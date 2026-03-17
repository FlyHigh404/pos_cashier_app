import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  SessionProvider({required this.sharedPreferences}) {
    _checkSavedSession();
  }

  String? _activeCashierName;

  bool get hasActiveSession => _activeCashierName != null && _activeCashierName!.isNotEmpty;
  
  String? get activeCashierName => _activeCashierName;

  void _checkSavedSession() {
    _activeCashierName = sharedPreferences.getString('active_cashier_name');
    notifyListeners();
  }

  // Start Session (Login Cashier)
  Future<void> startSession(String name) async {
    _activeCashierName = name;
    await sharedPreferences.setString('active_cashier_name', name);
    notifyListeners();
  }

  // End Session (Logout Cashier)
  Future<void> endSession() async {
    _activeCashierName = null;
    await sharedPreferences.remove('active_cashier_name');
    notifyListeners();
  }
}