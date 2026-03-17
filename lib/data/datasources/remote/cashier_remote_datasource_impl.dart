import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/common/result.dart';
import '../../models/cashier_model.dart';

// Gunakan nama 'CashierDatasource' agar konsisten dengan 'ProductDatasource'
abstract class CashierDatasource {
  Future<Result<List<CashierModel>>> getAllCashiers(String userId);
  Future<Result<void>> createCashier(CashierModel cashier);
  Future<Result<void>> updateCashier(CashierModel cashier);
  Future<Result<void>> deleteCashier(String id);
}

class CashierRemoteDatasourceImpl extends CashierDatasource {
  final FirebaseFirestore _firebaseFirestore;

  CashierRemoteDatasourceImpl(this._firebaseFirestore);

  @override
  Future<Result<List<CashierModel>>> getAllCashiers(String userId) async {
    try {
      var res = await _firebaseFirestore
          .collection('Cashier')
          .where('createdById', isEqualTo: userId)
          .get();
      var data = res.docs.map((e) => CashierModel.fromJson(e.data())).toList();
      return Result.success(data: data);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> createCashier(CashierModel cashier) async {
    try {
      await _firebaseFirestore.collection('Cashier').doc(cashier.id).set(cashier.toJson());
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCashier(CashierModel cashier) async {
    try {
      await _firebaseFirestore
          .collection('Cashier')
          .doc(cashier.id)
          .set(cashier.toJson(), SetOptions(merge: true));
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCashier(String id) async {
    try {
      await _firebaseFirestore.collection('Cashier').doc(id).delete();
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}