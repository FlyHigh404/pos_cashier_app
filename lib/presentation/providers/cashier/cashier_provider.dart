import 'package:flutter/foundation.dart';
import '../../../domain/entities/cashier_entity.dart';
import '../../../domain/repositories/cashier_repository.dart';
import '../auth/auth_provider.dart';

class CashiersProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final CashierRepository cashierRepository;

  CashiersProvider({
    required this.authProvider,
    required this.cashierRepository,
  });

  List<CashierEntity>? allCashiers;
  bool isLoading = false;

  Future<void> fetchCashiers() async {
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      debugPrint("Error: User ID is null. Make sure you are logged in.");
      return;
    }

    isLoading = true;
    notifyListeners();

    // 1. Fetch using the required userId
    final res = await cashierRepository.getAllCashiers(userId);

    if (res.isSuccess) {
      allCashiers = res.data ?? [];

      // 2. Auto-generate Admin if the list is empty
      if (allCashiers!.isEmpty) {
        debugPrint("No cashiers found. Auto-generating Admin account...");
        
        final adminCashier = CashierEntity(
          id: 'ADMIN_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Admin',
          isAvailable: true, // Matches your Entity
          createdById: userId, // Matches your Entity
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await cashierRepository.createCashier(adminCashier);
        
        // Refresh the list after creation
        final refreshRes = await cashierRepository.getAllCashiers(userId);
        allCashiers = refreshRes.data ?? [];
      }
    } else {
      debugPrint("Error fetching cashiers: ${res.error}");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addCashier(String name) async {
    final userId = authProvider.user?.id;
    if (userId == null) return false;

    final newCashier = CashierEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      name: name,
      isAvailable: true,
      createdById: userId,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final res = await cashierRepository.createCashier(newCashier);
    
    if (res.isSuccess) {
      await fetchCashiers(); // Refresh list after adding
      return true;
    }
    return false;
  }

  Future<bool> deleteCashier(String id) async {
    final res = await cashierRepository.deleteCashier(id);
    
    if (res.isSuccess) {
      // Optimistic UI update: remove from local list immediately
      allCashiers?.removeWhere((element) => element.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}