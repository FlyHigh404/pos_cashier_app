import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utilities/console_logger.dart';
import 'database_config.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase _instance = AppDatabase._internal();

  static AppDatabase get instance => _instance;

  late Database database;

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI
      sqfliteFfiInit();
    }

    // Get the path to the database
    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    if (kDebugMode) {
      // Only for development purpose
      // await dropDatabase(path);
    }

    // Create database if not exists
    File databaseFile = File(path);

    if (!await databaseFile.exists()) await databaseFile.create();

    // Open database
    database = await openDatabase(path);

    // Create tables
    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createCategoryTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
      database.execute(DatabaseConfig.createCashierTable),
    ]);

    await _seedCategories();
  }

  Future<void> _seedCategories() async {
    try {
      // Check if categories already exist
      final List<Map<String, dynamic>> existing = await database.query(DatabaseConfig.categoryTableName);
      
      if (existing.isEmpty) {
        cl("Seeding initial categories...");
        final List<String> initialCategories = ['Paket Bakso', 'Bakso Plecing', 'Minuman', 'Addon', 'Gorengan', 'Lainnya'];
        
        for (var name in initialCategories) {
          await database.insert(DatabaseConfig.categoryTableName, {
            'name': name,
          });
        }
        cl("Seeding complete!");
      }
    } catch (e) {
      ce("Error seeding categories: $e");
    }
  }

  @visibleForTesting
  Future<void> initTestDatabase({required Database testDatabase}) async {
    database = testDatabase;

    // Create tables
    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createCategoryTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
      database.execute(DatabaseConfig.createCashierTable),
    ]);
  }

  Future<void> dropDatabase(String path) async {
    // Check if the database file exists
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      // Delete the database file
      await databaseFile.delete();

      cw('Database deleted successfully!');
    } else {
      ce('Database does not exist!');
    }
  }
}
