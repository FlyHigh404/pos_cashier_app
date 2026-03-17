import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_config.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../interfaces/product_datasource.dart';

class ProductLocalDatasourceImpl extends ProductDatasource {
  final AppDatabase _appDatabase;

  ProductLocalDatasourceImpl(this._appDatabase);

  @override
  Future<Result<int>> createProduct(ProductModel product) async {
    try {
      await _appDatabase.database.insert(
        DatabaseConfig.productTableName,
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // The id has been generated in models
      return Result.success(data: product.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductModel product) async {
    try {
      await _appDatabase.database.update(
        DatabaseConfig.productTableName,
        product.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    try {
      await _appDatabase.database.delete(
        DatabaseConfig.productTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProduct(int id) async {
    try {
      var res = await _appDatabase.database.query(
        DatabaseConfig.productTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (res.isEmpty) return Result.success(data: null);

      return Result.success(data: ProductModel.fromJson(res.first));
    } catch (e) {
      return Result.failure(error: e);
    }
  }
  @override
  Future<Result<List<CategoryModel>>> getCategories() async {
    try {
      final res = await _appDatabase.database.query(DatabaseConfig.categoryTableName);
      final categories = res.map((e) => CategoryModel.fromJson(e)).toList();
      return Result.success(data: categories);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getAllUserProducts(String userId) async {
    try {
      var res = await _appDatabase.database.query(
        DatabaseConfig.productTableName,
        where: 'createdById = ?',
        whereArgs: [userId],
      );

      return Result.success(
        data: res.map((e) => ProductModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
    int? categoryId,
  }) async {
    try {
      String whereClause = 'createdById = ? AND name LIKE ?';
      List<dynamic> whereArgs = [userId, "%${contains ?? ''}%"];

      if (categoryId != null) {
        whereClause += ' AND categoryId = ?';
        whereArgs.add(categoryId);
      }

      var res = await _appDatabase.database.query(
        DatabaseConfig.productTableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '$orderBy $sortBy',
        limit: limit,
        offset: offset,
      );

      return Result.success(
        data: res.map((e) => ProductModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> createCategory(CategoryModel category) async {
    try {
      final id = await _appDatabase.database.insert(
        DatabaseConfig.categoryTableName,
        category.toJson(),
      );
      return Result.success(data: id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCategory(CategoryModel category) async {
    try {
      await _appDatabase.database.update(
        DatabaseConfig.categoryTableName,
        category.toJson(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCategory(int id) async {
    try {
      // Note: You might want to check if products are linked to this category first
      await _appDatabase.database.delete(
        DatabaseConfig.categoryTableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
