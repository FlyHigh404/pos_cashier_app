import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../core/common/result.dart';
import '../../core/constants/constants.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../domain/entities/cashier_entity.dart';
import '../../domain/repositories/cashier_repository.dart';
import '../datasources/local/cashier_local_datasource_impl.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/remote/cashier_remote_datasource_impl.dart';
import '../models/cashier_model.dart';
import '../models/queued_action_model.dart';

class CashierRepositoryImpl extends CashierRepository {
  final PingService pingService;
  final CashierLocalDataSource cashierLocalDatasource;
  final CashierRemoteDatasourceImpl cashierRemoteDatasource;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;

  CashierRepositoryImpl({
    required this.pingService,
    required this.cashierLocalDatasource,
    required this.cashierRemoteDatasource,
    required this.queuedActionLocalDatasource,
  });

  @override
  Future<Result<List<CashierEntity>>> getAllCashiers(String userId) async {
    try {
      final local = await cashierLocalDatasource.getAllCashiers(userId);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await pingService.isConnected) {
        final remote = await cashierRemoteDatasource.getAllCashiers(userId);
        if (remote.isFailure) return Result.failure(error: remote.error!);

        // Menggunakan Isolate untuk komputasi berat
        final syncResult = await compute(_runSyncInIsolate, {
          'local': local.data!,
          'remote': remote.data!,
          'tolerance': Constants.minSyncIntervalToleranceForCriticalInMinutes,
        });

        int syncedToLocal = 0;
        int syncedToRemote = 0;

        // Terapkan hasil sinkronisasi ke database
        for (var action in syncResult.actionsToLocal) {
          final res = await cashierLocalDatasource.insertCashier(action);
          if (res.isSuccess) syncedToLocal++;
        }

        for (var action in syncResult.actionsToRemote) {
          final res = await cashierRemoteDatasource.updateCashier(action);
          if (res.isSuccess) syncedToRemote++;
        }
        
        if (syncedToLocal > syncedToRemote) {
          return Result.success(data: remote.data!.map((e) => e.toEntity()).toList());
        }
      }

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  // Logika sinkronisasi dipindahkan ke Isolate agar UI tetap lancar
  static SyncActionResult _runSyncInIsolate(Map<String, dynamic> params) {
    final List<CashierModel> local = params['local'];
    final List<CashierModel> remote = params['remote'];
    final int tolerance = params['tolerance'];

    List<CashierModel> toLocal = [];
    List<CashierModel> toRemote = [];
    final processedIds = <String>{};

    for (final localData in local) {
      final matchRemote = remote.where((r) => r.id == localData.id).firstOrNull;
      if (matchRemote != null) {
        processedIds.add(localData.id!);
        final updatedAtLocal = DateTime.tryParse(localData.updatedAt ?? '');
        final updatedAtRemote = DateTime.tryParse(matchRemote.updatedAt ?? '');
        if (updatedAtLocal == null || updatedAtRemote == null) continue;

        final diff = updatedAtRemote.difference(updatedAtLocal).inMinutes;
        if (diff.abs() > tolerance) {
          if (diff > 0) toLocal.add(matchRemote);
          else toRemote.add(localData);
        }
      } else {
        processedIds.add(localData.id!);
        toRemote.add(localData);
      }
    }

    for (final remoteData in remote) {
      if (!processedIds.contains(remoteData.id)) toLocal.add(remoteData);
    }

    return SyncActionResult(toLocal, toRemote);
  }

  @override
  Future<Result<void>> createCashier(CashierEntity cashier) async {
    try {
      final data = CashierModel.fromEntity(cashier);
      final local = await cashierLocalDatasource.insertCashier(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await await pingService.isConnected) {
        final remote = await cashierRemoteDatasource.createCashier(data);
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'CashierRepositoryImpl',
            method: 'createCashier',
            param: jsonEncode(data.toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCashier(CashierEntity cashier) async {
    try {
      final data = CashierModel.fromEntity(cashier);
      final local = await cashierLocalDatasource.updateCashier(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await await pingService.isConnected) {
        final remote = await cashierRemoteDatasource.updateCashier(data);
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'CashierRepositoryImpl',
            method: 'updateCashier',
            param: jsonEncode(data.toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCashier(String cashierId) async {
    try {
      final local = await cashierLocalDatasource.deleteCashier(cashierId);
      if (local.isFailure) return Result.failure(error: local.error!);

      if (await pingService.isConnected) {
        final remote = await cashierRemoteDatasource.deleteCashier(cashierId);
        if (remote.isFailure) return Result.failure(error: remote.error!);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'CashierRepositoryImpl',
            method: 'deleteCashier',
            param: cashierId,
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}

class SyncActionResult {
  final List<CashierModel> actionsToLocal;
  final List<CashierModel> actionsToRemote;
  SyncActionResult(this.actionsToLocal, this.actionsToRemote);
}