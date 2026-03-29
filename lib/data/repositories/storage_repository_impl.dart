import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/common/result.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/remote/storage_remote_datasource_impl.dart';

class StorageRepositoryImpl implements StorageRepository {
  final PingService pingService;
  final StorageRemoteDataSourceImpl storageRemoteDataSource;

  StorageRepositoryImpl({
    required this.pingService,
    required this.storageRemoteDataSource,
  });

  @override
  Future<Result<String>> uploadUserPhoto(String imgPath) async {
    try {
      if (!await pingService.isConnected) {
        final File tempFile = File(imgPath);
        
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String offlineDirPath = p.join(appDocDir.path, 'offline_images');
        final Directory offlineDir = Directory(offlineDirPath);

        if (!await offlineDir.exists()) {
          await offlineDir.create(recursive: true);
        }

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imgPath)}';
        final String newLocalPath = p.join(offlineDirPath, fileName);

        final File permanentFile = await tempFile.copy(newLocalPath);

        return Result.success(data: permanentFile.path);
      }

      final res = await storageRemoteDataSource.uploadUserPhoto(imgPath);
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> uploadProductImage(String imgPath) async {
    try {
      if (!await pingService.isConnected) {
        final File tempFile = File(imgPath);
        
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String offlineDirPath = p.join(appDocDir.path, 'offline_images');
        final Directory offlineDir = Directory(offlineDirPath);

        if (!await offlineDir.exists()) {
          await offlineDir.create(recursive: true);
        }

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imgPath)}';
        final String newLocalPath = p.join(offlineDirPath, fileName);

        final File permanentFile = await tempFile.copy(newLocalPath);

        return Result.success(data: permanentFile.path);
      }

      final res = await storageRemoteDataSource.uploadProductImage(imgPath);
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
