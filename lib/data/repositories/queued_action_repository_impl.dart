import 'dart:convert';
import 'dart:io';

import '../../core/common/result.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../core/utilities/console_logger.dart';
import '../../domain/entities/queued_action_entity.dart';
import '../../domain/repositories/queued_action_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/remote/product_remote_datasource_impl.dart';
import '../datasources/remote/transaction_remote_datasource_impl.dart';
import '../datasources/remote/user_remote_datasource_impl.dart';
import '../datasources/remote/cashier_remote_datasource_impl.dart';
import '../models/product_model.dart';
import '../models/queued_action_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/cashier_model.dart';

class QueuedActionRepositoryImpl extends QueuedActionRepository {
  final PingService pingService;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;
  final UserRemoteDatasourceImpl userRemoteDatasource;
  final TransactionRemoteDatasourceImpl transactionRemoteDatasource;
  final ProductRemoteDatasourceImpl productRemoteDatasource;
  final CashierRemoteDatasourceImpl cashierRemoteDatasource;
  final StorageRepository storageRepository;
  final ProductLocalDatasourceImpl productLocalDatasource;

  QueuedActionRepositoryImpl({
    required this.pingService,
    required this.queuedActionLocalDatasource,
    required this.userRemoteDatasource,
    required this.transactionRemoteDatasource,
    required this.productRemoteDatasource,
    required this.cashierRemoteDatasource,
    required this.storageRepository,
    required this.productLocalDatasource,
  });

  @override
  Future<Result<List<QueuedActionEntity>>> getAllQueuedAction() async {
    try {
      final res = await queuedActionLocalDatasource.getAllUserQueuedAction();
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<bool>>> executeAllQueuedActions(
    List<QueuedActionEntity> queues,
  ) async {
    try {
      if (queues.isEmpty) return Result.success(data: []);

      List<bool> result = [];

      for (final queue in queues) {
        // Pass if the internet goes off in the process
        if (!await pingService.isConnected) continue;

        final res = await executeQueuedAction(queue);

        result.add(res.isSuccess);
      }

      return Result.success(data: result);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<ProductModel>> _processQueuedImage(ProductModel param) async {
    if (param.imageUrl.isNotEmpty && !param.imageUrl.startsWith('http')) {
      final file = File(param.imageUrl);
      if (file.existsSync()) {
        final uploadRes = await storageRepository
            .uploadProductImage(param.imageUrl)
            .timeout(const Duration(seconds: 15));
            
        if (uploadRes.isSuccess) {
          param.imageUrl = uploadRes.data!;
          // Update local DB so it matches the cloud url
          await productLocalDatasource.updateProduct(param);
        } else {
          // Return failure so the queue aborts and retries later!
          return Result.failure(error: 'Upload failed or timed out');
        }
      } else {
        param.imageUrl = ''; // File was deleted from phone, clear the URL to prevent crash
        await productLocalDatasource.updateProduct(param);
      }
    }
    return Result.success(data: param);
  }

  @override
  Future<Result<bool>> executeQueuedAction(QueuedActionEntity queue) async {
    try {
      cl(QueuedActionModel.fromEntity(queue).toJson());

      final res = await _functionSelector(queue);

      if (res.isSuccess) {
        // Delete executed queue from db
        final deleteRes = await queuedActionLocalDatasource.deleteQueuedAction(
          queue.id!,
        );
        if (deleteRes.isFailure) return Result.failure(error: res.error!);

        return Result.success(data: true);
      } else {
        return Result.failure(error: res.error ?? 'Unknown error');
      }
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<Null>> _functionSelector(QueuedActionEntity queue) async {
    try {
      if (queue.repository == 'UserRepositoryImpl') {
        if (queue.method == 'createUser') {
          UserModel param = UserModel.fromJson(jsonDecode(queue.param));

          final res = await userRemoteDatasource.createUser(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'deleteUser') {
          final param = queue.param;

          final res = await userRemoteDatasource.deleteUser(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'updateUser') {
          UserModel param = UserModel.fromJson(jsonDecode(queue.param));

          final res = await userRemoteDatasource.updateUser(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }
      }

      if (queue.repository == 'TransactionRepositoryImpl') {
        if (queue.method == 'createTransaction') {
          TransactionModel param = TransactionModel.fromJson(
            jsonDecode(queue.param),
          );

          final res = await transactionRemoteDatasource.createTransaction(
            param,
          );
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'deleteTransaction') {
          final param = int.parse(queue.param);

          final res = await transactionRemoteDatasource.deleteTransaction(
            param,
          );
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'softDeleteTransaction') {
          final param = int.parse(queue.param);

          final res = await transactionRemoteDatasource.softDeleteTransaction(
            param,
          );
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'updateTransaction') {
          TransactionModel param = TransactionModel.fromJson(
            jsonDecode(queue.param),
          );

          final res = await transactionRemoteDatasource.updateTransaction(
            param,
          );
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }
      }

      if (queue.repository == 'ProductRepositoryImpl') {
        if (queue.method == 'createProduct') {
          ProductModel param = ProductModel.fromJson(jsonDecode(queue.param));

          final imageRes = await _processQueuedImage(param);
          if (imageRes.isFailure) return Result.failure(error: imageRes.error!);
          param = imageRes.data!;

          final res = await productRemoteDatasource.createProduct(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'deleteProduct') {
          final param = int.parse(queue.param);

          final res = await productRemoteDatasource.deleteProduct(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'updateProduct') {
          ProductModel param = ProductModel.fromJson(jsonDecode(queue.param));

          final imageRes = await _processQueuedImage(param);
          if (imageRes.isFailure) return Result.failure(error: imageRes.error!);
          param = imageRes.data!;
          
          final res = await productRemoteDatasource.updateProduct(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }
      }
      
      if (queue.repository == 'CashierRepositoryImpl') {
        if (queue.method == 'createCashier') {
          CashierModel param = CashierModel.fromJson(jsonDecode(queue.param));

          final res = await cashierRemoteDatasource.createCashier(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'deleteCashier') {
          final param = queue.param;

          final res = await cashierRemoteDatasource.deleteCashier(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }

        if (queue.method == 'updateCashier') {
          CashierModel param = CashierModel.fromJson(jsonDecode(queue.param));

          final res = await cashierRemoteDatasource.updateCashier(param);
          if (res.isFailure) return Result.failure(error: res.error!);

          return Result.success(data: null);
        }
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
