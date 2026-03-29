import 'dart:convert';
import 'dart:io';
import '../../core/utilities/console_logger.dart';

import '../../core/common/result.dart';
import '../../core/constants/constants.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/remote/product_remote_datasource_impl.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/queued_action_model.dart';

class ProductRepositoryImpl extends ProductRepository {
  final PingService pingService;
  final ProductLocalDatasourceImpl productLocalDatasource;
  final ProductRemoteDatasourceImpl productRemoteDatasource;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;
  final StorageRepository storageRepository;

  ProductRepositoryImpl({
    required this.pingService,
    required this.productLocalDatasource,
    required this.productRemoteDatasource,
    required this.queuedActionLocalDatasource,
    required this.storageRepository,
  });

  @override
  Future<Result<int>> syncAllUserProducts(String userId) async {
    try {
      if (await pingService.isConnected) {
        final local = await productLocalDatasource.getAllUserProducts(userId);
        if (local.isFailure) return Result.failure(error: local.error!);

        final remote = await productRemoteDatasource.getAllUserProducts(userId);
        if (remote.isFailure) return Result.failure(error: remote.error!);

        final res = await _syncProducts(local.data!, remote.data!);

        // Sum all local and remote sync counts
        int totalSyncedCount = res.$1 + res.$2;

        // Return synced data count
        return Result.success(data: totalSyncedCount);
      }

      return Result.success(data: 0);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy = 'sold',
    String sortBy = 'DESC',
    int limit = 10000,
    int? offset,
    String? contains,
    int? categoryId,
  }) async {
    try {
      final local = await productLocalDatasource.getUserProducts(
        userId,
        orderBy: orderBy,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        contains: contains,
        categoryId: categoryId,
      );

      if (local.isFailure) return Result.failure(error: local.error!);
      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<ProductEntity?>> getProduct(int productId) async {
    try {
      // OFFLINE FIRST: Read ONLY from local database
      final local = await productLocalDatasource.getProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<int>> createCategory(CategoryEntity category) async {
    // Map Entity to Model
    final model = CategoryModel(name: category.name);
    return await productLocalDatasource.createCategory(model);
  }

  @override
  Future<Result<void>> deleteCategory(int id) async {
    return await productLocalDatasource.deleteCategory(id);
  }

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    final res = await productLocalDatasource.getCategories();
    
    if (res.isSuccess) {
      return Result.success(data: res.data!.map((e) => e.toEntity()).toList());
    }
    
    return Result.failure(error: res.error!); 
  }

  @override
  Future<List<ProductEntity>> getProducts({int? categoryId}) async {
    final res = await productLocalDatasource.getUserProducts(
      "",
      contains: null, 
    );
    
    if (res.isSuccess) {
      var products = res.data!.map((e) => e.toEntity()).toList();
      if (categoryId != null) {
        return products.where((p) => p.categoryId == categoryId).toList();
      }
      return products;
    }

    return [];
  }

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product);

      final local = await productLocalDatasource.createProduct(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      final localProductId = local.data!;
      
      final jsonString = jsonEncode(data.toJson());
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      jsonMap['id'] = localProductId;

      var safeDataWithId = ProductModel.fromJson(jsonMap);
      safeDataWithId = await _ensureRemoteImage(safeDataWithId);

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.createProduct(safeDataWithId);
        if (remote.isFailure) {
          await _queueProductAction('createProduct', jsonEncode(safeDataWithId.toJson()));
        }
      } else {
        await _queueProductAction('createProduct', jsonEncode(safeDataWithId.toJson()));
      }

      if (safeDataWithId.imageUrl.startsWith('http')) {
        await productLocalDatasource.updateProduct(safeDataWithId);
      }

      return Result.success(data: localProductId);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<void>> deleteProduct(int productId) async {
    try {
      final local = await productLocalDatasource.deleteProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.deleteProduct(productId);
        if (remote.isFailure) {
          await _queueProductAction('deleteProduct', productId.toString());
        }
      } else {
        await _queueProductAction('deleteProduct', productId.toString());
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString()); // 🚀 FIXED: Always return a string!
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product);

      final local = await productLocalDatasource.updateProduct(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      final jsonString = jsonEncode(data.toJson());
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      var safeData = ProductModel.fromJson(jsonMap);
      safeData = await _ensureRemoteImage(safeData);

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.updateProduct(safeData);
        if (remote.isFailure) {
          await _queueProductAction('updateProduct', jsonEncode(safeData.toJson()));
        }
      } else {
        await _queueProductAction('updateProduct', jsonEncode(safeData.toJson()));
      }
      if (safeData.imageUrl.startsWith('http')) {
        await productLocalDatasource.updateProduct(safeData);
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  // Perform a sync between local and remote data
  Future<(int, int)> _syncProducts(List<ProductModel> local, List<ProductModel> remote) async {
    int syncedToLocalCount = 0;
    int syncedToRemoteCount = 0;

    final processedIds = <int>{};

    // Process local products first
    for (final localData in local) {
      final matchRemoteData = remote.where((remoteData) => remoteData.id == localData.id).firstOrNull;

      if (matchRemoteData != null) {
        processedIds.add(localData.id);

        final updatedAtLocal = DateTime.tryParse(localData.updatedAt ?? '');
        final updatedAtRemote = DateTime.tryParse(matchRemoteData.updatedAt ?? '');

        // Skip if either timestamp is invalid
        if (updatedAtLocal == null || updatedAtRemote == null) continue;

        final differenceInMinutes = updatedAtRemote.difference(updatedAtLocal).inMinutes;
        final isDiffSignificant = differenceInMinutes.abs() > Constants.minSyncIntervalToleranceForCriticalInMinutes;

        // Check which is newer based on the difference
        final isRemoteNewer = isDiffSignificant && differenceInMinutes > 0;
        final isLocalNewer = isDiffSignificant && differenceInMinutes < 0;

        if (isRemoteNewer) {
          // Save remote data to local db
          final res = await productLocalDatasource.updateProduct(matchRemoteData);
          if (res.isSuccess) syncedToLocalCount += 1;
        } else if (isLocalNewer) {
          
          var safeLocalData = await _ensureRemoteImage(localData);
          
          // Update remote with local data
          final res = await productRemoteDatasource.updateProduct(safeLocalData);
          if (res.isSuccess) {
            syncedToRemoteCount += 1;
            if (safeLocalData.imageUrl.startsWith('http')) {
              await productLocalDatasource.updateProduct(safeLocalData);
            }
          }
        }
        // If not significant difference, do nothing (already in sync)
      } else {
        // No matching remote product, create it
        processedIds.add(localData.id);

        var safeLocalData = await _ensureRemoteImage(localData);

        final res = await productRemoteDatasource.createProduct(safeLocalData);
        if (res.isSuccess) {
          syncedToRemoteCount += 1;
          if (safeLocalData.imageUrl.startsWith('http')) {
            await productLocalDatasource.updateProduct(safeLocalData);
          }
        }
      }
    }

    for (final remoteData in remote) {
      // Skip if already processed in the first loop
      if (processedIds.contains(remoteData.id)) continue;

      // No matching local product, create it locally
      final res = await productLocalDatasource.createProduct(remoteData);
      if (res.isSuccess) syncedToLocalCount += 1;
    }

    return (syncedToLocalCount, syncedToRemoteCount);
  }

  Future<void> _queueProductAction(String method, String param) async {
    await queuedActionLocalDatasource.createQueuedAction(
      QueuedActionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        repository: 'ProductRepositoryImpl',
        method: method,
        param: param,
        isCritical: true,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<ProductModel> _ensureRemoteImage(ProductModel model) async {
    if (model.imageUrl.isEmpty || model.imageUrl.startsWith('http')) {
      return model;
    }

    // upload
    if (await pingService.isConnected) {
      try {
        final file = File(model.imageUrl);
        if (!file.existsSync()) {
          cl('⚠️ Offline image lost: ${model.imageUrl}');
          model.imageUrl = '';
          return model;
        }

        final uploadResult = await storageRepository
            .uploadProductImage(model.imageUrl)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => Result.failure(error: 'Upload timed out'),
            );
        
        if (uploadResult.isSuccess) {
          model.imageUrl = uploadResult.data!; 
        } else {
          cl('⚠️ Upload Failed/Timed Out: ${uploadResult.error}');
        }
      } catch (e) {
        cl('⚠️ Upload Crashed: $e');
      }
    }
    
    return model; // If offline or upload fails, keep the local path
  }


}
