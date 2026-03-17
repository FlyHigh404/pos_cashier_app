import '../../core/common/result.dart';
import '../entities/cashier_entity.dart';

abstract class CashierRepository {
  Future<Result<List<CashierEntity>>> getAllCashiers(String userId); 
  Future<Result<void>> createCashier(CashierEntity cashier);
  Future<Result<void>> updateCashier(CashierEntity cashier);
  Future<Result<void>> deleteCashier(String cashierId);
}