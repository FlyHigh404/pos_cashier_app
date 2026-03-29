import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../core/services/connectivity/ping_service.dart';
import '../../../core/services/info/device_info_service.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/entities/user_entity.dart' hide AuthProvider;
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/cashier_repository.dart';
import '../../../domain/usecases/params/no_param.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../../domain/usecases/queued_action_usecases.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../../widgets/app_snack_bar.dart';
import '../auth/auth_provider.dart';
import '../products/products_provider.dart';

class MainProvider extends ChangeNotifier {
  final PingService pingService;
  final DeviceInfoService deviceInforService;
  final AuthProvider authProvider;
  final UserRepository userRepository;
  final ProductRepository productRepository;
  final TransactionRepository transactionRepository;
  final QueuedActionRepository queuedActionRepository;
  final CashierRepository cashierRepository;
  final ProductsProvider productsProvider;

  MainProvider({
    required this.pingService,
    required this.deviceInforService,
    required this.authProvider,
    required this.transactionRepository,
    required this.userRepository,
    required this.productRepository,
    required this.queuedActionRepository,
    required this.productsProvider,
    required this.cashierRepository,
  });

  bool isLoaded = false;
  bool isHasInternet = true;
  bool isHasQueuedActions = false;
  bool isSyncronizing = false;

  UserEntity? user;
  Timer? _watchdogTimer;

  Future<void> initMainProvider() async {
    startPingService();
    isLoaded = true;
    notifyListeners();
  }

  Future<void> startPingService() async {
    final isPhysicalDevice = await deviceInforService.checkDeviceType();
    final host = isPhysicalDevice ? '8.8.8.8' : '127.0.0.1';

    pingService.startPing(host: host);
    pingService.addConnectionStatusListener(
      (isConnected) => onHasInternet(isConnected),
    );

    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Manually check the true connection status
      bool actuallyConnected = await pingService.isConnected;

      // If the true connection is different from our UI state, the stream died!
      if (actuallyConnected != isHasInternet) {
        onHasInternet(actuallyConnected);

        // If internet came back, forcefully restart the dead ping stream
        if (actuallyConnected) {
          pingService.startPing(host: host);
        }
      }
    });
  }

  Future<void> checkAndSyncAllData() async {
    // Prevent sync during first time app open
    if (!isLoaded || !isHasInternet) return;

    try {
      isSyncronizing = true;
      notifyListeners();

      // Sync all data
      await executeAllQueuedActions();
      await getAndSyncAllUserData();

      // Re-check queued actions
      checkIsHasQueuedActions();

      isSyncronizing = false;
      notifyListeners();
    } catch (e) {
      isSyncronizing = false;
      notifyListeners();

      AppSnackBar.showError('Failed to sync data\n\n${e.toString()}');
    }
  }

  Future<void> getAndSyncAllUserData() async {
    var userId = authProvider.user?.id;
    if (userId == null) throw 'Unathenticated!';

    // Run multiple futures simultaneusly
    // Because each repository has beed added data checker method
    // The local db will automatically sync with cloud db or vice versa
    var res = await Future.wait([
      GetUserUsecase(userRepository).call(userId),
      SyncAllUserProductsUsecase(productRepository).call(userId),
      SyncAllUserTransactionsUsecase(transactionRepository).call(userId),
      cashierRepository.getAllCashiers(userId),
    ]);

    // Set and notify user state
    if (res.first.isSuccess) {
      user = res.first.data as UserEntity?;
      notifyListeners();
    }

    if (res[1].isFailure) AppSnackBar.showError("Gagal sinkronisasi data produk");
    if (res[2].isFailure) AppSnackBar.showError("Gagal sinkronisasi data transaksi");
    if (res[3].isFailure) AppSnackBar.showError("Gagal sinkronisasi data kasir");

    // Refresh products list
    productsProvider.getAllProducts();

    // Start downloading images in the background
    _precacheMenuImages();

    // Check queued actions
    checkIsHasQueuedActions();

    // Notify to MainScreen
    isLoaded = true;
    notifyListeners();
  }

  Future<int> executeAllQueuedActions() async {
    var queuedActions = await getQueuedActions();

    if (queuedActions.isNotEmpty) {
      var res = await ExecuteAllQueuedActionUsecase(queuedActionRepository).call(queuedActions);

      int executedCount = res.data?.where((e) => e).length ?? 0;
      return executedCount;
    }

    return 0;
  }

  Future<List<QueuedActionEntity>> getQueuedActions() async {
    var res = await GetAllQueuedActionUsecase(queuedActionRepository).call(NoParam());
    return res.data ?? [];
  }

  Future<void> onHasInternet(bool value) async {
    isHasInternet = value;
    notifyListeners();

    if (isHasInternet) checkAndSyncAllData();
  }

  Future<void> checkIsHasQueuedActions() async {
    isHasQueuedActions = (await getQueuedActions()).isEmpty;
    notifyListeners();
  }

  Future<void> _precacheMenuImages() async {
    // Get the latest products we just synced
    final products = productsProvider.allProducts ?? productsProvider.categories.expand((c) => []).toList(); 
    final allProductsRes = await productRepository.getProducts();
    
    if (allProductsRes.isNotEmpty) {
      for (var product in allProductsRes) {
        if (product.imageUrl.isNotEmpty) {
          try {
            await DefaultCacheManager().downloadFile(product.imageUrl);
          } catch (e) {
            debugPrint('Gagal download gambar: ${product.imageUrl}');
          }
        }
      }
    }
  }
}
