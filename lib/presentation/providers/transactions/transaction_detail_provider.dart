import 'package:flutter/foundation.dart';

import '../../../core/common/result.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/usecases/transaction_usecases.dart';

class TransactionDetailProvider extends ChangeNotifier {
  final TransactionRepository transactionRepository;

  TransactionDetailProvider({required this.transactionRepository});

  TransactionEntity? currentTransaction;

  Future<TransactionEntity?> getTransactionDetail(int id) async {
    if (currentTransaction != null && currentTransaction!.id == id) {
      return currentTransaction;
    }

    var res = await GetTransactionUsecase(transactionRepository).call(id);

    if (res.isSuccess) {
      currentTransaction = res.data;
      Future.microtask(() => notifyListeners());
      return res.data;
    } else {
      throw res.error ?? 'Failed to load data';
    }
  }

  Future<Result<void>> softDeleteTransaction(int id) async {
    var res = await SoftDeleteTransactionUsecase(transactionRepository).call(id);

    if (res.isSuccess) {
      if (currentTransaction?.id == id) {
        currentTransaction = null;
        notifyListeners();
      }
    }

    return res;
  }
  
  void clearTransaction() {
    currentTransaction = null;
  }

  Future<Result<void>> deleteTransaction(int id) async {
    var res = await DeleteTransactionUsecase(transactionRepository).call(id);

    if (res.isSuccess) {
      if (currentTransaction?.id == id) {
        currentTransaction = null;
        notifyListeners();
      }
    }

    return res;
  }

  

  Future<void> markAsSuccess(TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final jsonMap = model.toJson();
      
      jsonMap['status'] = 'success';
      
      final updatedModel = TransactionModel.fromJson(jsonMap).toEntity();
      
      var res = await UpateTransactionUsecase(transactionRepository).call(updatedModel);
      
      if (res.isSuccess) {
        currentTransaction = updatedModel;
        notifyListeners();
      } else {
        debugPrint('Gagal update status: ${res.error}');
      }
    } catch (e) {
      debugPrint('Gagal update status: $e');
    }
  }
}
