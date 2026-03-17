import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_config.dart';
import '../../models/cashier_model.dart';

abstract class CashierLocalDataSource {
  Future<Result<List<CashierModel>>> getAllCashiers(String userId);
  Future<Result<void>> insertCashier(CashierModel cashier);
  Future<Result<void>> updateCashier(CashierModel cashier);
  Future<Result<void>> deleteCashier(String id);
}

class CashierLocalDataSourceImpl implements CashierLocalDataSource {
  final AppDatabase _appDatabase;

  CashierLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Result<List<CashierModel>>> getAllCashiers(String userId) async {
    try {
      var res = await _appDatabase.database.query(
        DatabaseConfig.cashierTableName,
        where: 'is_active = ? AND created_by_id = ?',
        whereArgs: [1, userId],
        orderBy: 'name ASC',
      );

      return Result.success(
        data: res.map((e) => CashierModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> insertCashier(CashierModel cashier) async {
    try {
      await _appDatabase.database.insert(
        DatabaseConfig.cashierTableName,
        cashier.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCashier(CashierModel cashier) async {
    try {
      await _appDatabase.database.update(
        DatabaseConfig.cashierTableName,
        cashier.toJson(),
        where: 'id = ?',
        whereArgs: [cashier.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCashier(String id) async {
    try {
      await _appDatabase.database.update(
        DatabaseConfig.cashierTableName,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}