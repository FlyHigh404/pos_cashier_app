import 'dart:convert';

import '../../core/common/result.dart';
import '../../core/constants/constants.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/product_repository.dart';
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

  ProductRepositoryImpl({
    required this.pingService,
    required this.productLocalDatasource,
    required this.productRemoteDatasource,
    required this.queuedActionLocalDatasource,
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

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.createProduct(data);
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        final res = await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'createProduct',
            param: jsonEncode((data).toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        if (res.isFailure) return Result.failure(error: res.error!);
      }

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int productId) async {
    try {
      final local = await productLocalDatasource.deleteProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.deleteProduct(productId);
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        final res = await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'deleteProduct',
            param: productId.toString(),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        if (res.isFailure) return Result.failure(error: res.error!);
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductEntity product) async {
    try {
      final local = await productLocalDatasource.updateProduct(ProductModel.fromEntity(product));
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await pingService.isConnected) {
        final remote = await productRemoteDatasource.updateProduct(ProductModel.fromEntity(product));
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        final res = await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'updateProduct',
            param: jsonEncode(ProductModel.fromEntity(product).toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        if (res.isFailure) return Result.failure(error: res.error!);
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  // Perform a sync between local and remote data
  Future<(int, int)> _syncProducts(List<ProductModel> local, List<ProductModel> remote) async {
    int syncedToLocalCount = 0;
    int syncedToRemoteCount = 0;

    // Track processed IDs to avoid duplicate syncing
    final processedIds = <int>{};

    // Process local products first
    for (final localData in local) {
      final matchRemoteData = remote.where((remoteData) => remoteData.id == localData.id).firstOrNull;

      if (matchRemoteData != null) {
        // Mark as processed
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
          // Update remote with local data
          final res = await productRemoteDatasource.updateProduct(localData);
          if (res.isSuccess) syncedToRemoteCount += 1;
        }
        // If not significant difference, do nothing (already in sync)
      } else {
        // No matching remote product, create it
        processedIds.add(localData.id);
        final res = await productRemoteDatasource.createProduct(localData);
        if (res.isSuccess) syncedToRemoteCount += 1;
      }
    }

    // Process remaining remote products that weren't in local
    for (final remoteData in remote) {
      // Skip if already processed in the first loop
      if (processedIds.contains(remoteData.id)) continue;

      // No matching local product, create it locally
      final res = await productLocalDatasource.createProduct(remoteData);
      if (res.isSuccess) syncedToLocalCount += 1;
    }

    return (syncedToLocalCount, syncedToRemoteCount);
  }


}
