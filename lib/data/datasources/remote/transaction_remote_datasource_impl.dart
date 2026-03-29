import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/common/result.dart';
import '../../models/ordered_product_model.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../interfaces/transaction_datasource.dart';

class TransactionRemoteDatasourceImpl extends TransactionDatasource {
  final FirebaseFirestore _firebaseFirestore;

  TransactionRemoteDatasourceImpl(this._firebaseFirestore);

  @override
  Future<Result<int>> createTransaction(TransactionModel transaction) async {
    try {
      final transactionId = await _firebaseFirestore.runTransaction((trx) async {
        List<DocumentSnapshot> productSnaps = [];
        List<DocumentReference> productRefs = [];

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          for (var orderedProduct in transaction.orderedProducts!) {
            var ref = _firebaseFirestore.collection('Product').doc('${orderedProduct.productId}');
            productRefs.add(ref);
            productSnaps.add(await trx.get(ref)); 
          }
        }

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          for (int i = 0; i < transaction.orderedProducts!.length; i++) {
            var orderedProduct = transaction.orderedProducts![i];
            orderedProduct.transactionId = transaction.id;
            
            var orderedProductRef = _firebaseFirestore.collection('OrderedProduct').doc('${orderedProduct.id}');
            trx.set(orderedProductRef, orderedProduct.toJson());

            // If product exists, update its stock
            if (productSnaps[i].data() != null) {
              var productMap = productSnaps[i].data() as Map<String, dynamic>;
              var product = ProductModel.fromJson(productMap);
              int sold = product.sold + orderedProduct.quantity;
              trx.update(productRefs[i], {'sold': sold});
            }
          }
        }

        var transactionRef = _firebaseFirestore.collection('Transaction').doc('${transaction.id}');
        trx.set(
          transactionRef,
          transaction.toJson()
            ..remove('orderedProducts')
            ..remove('createdBy'),
        );

        return transaction.id!;
      });

      return Result.success(data: transactionId);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<void>> updateTransaction(TransactionModel transaction) async {
    try {
      await _firebaseFirestore.runTransaction((trx) async {
        List<DocumentSnapshot> productSnaps = [];
        List<DocumentReference> productRefs = [];

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          for (var orderedProduct in transaction.orderedProducts!) {
            var ref = _firebaseFirestore.collection('Product').doc('${orderedProduct.productId}');
            productRefs.add(ref);
            productSnaps.add(await trx.get(ref));
          }
        }

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          for (int i = 0; i < transaction.orderedProducts!.length; i++) {
            var orderedProduct = transaction.orderedProducts![i];
            
            // Update ordered product doc
            var orderedProductRef = _firebaseFirestore.collection('OrderedProduct').doc('${orderedProduct.id}');
            trx.set(orderedProductRef, orderedProduct.toJson());

            // If transaction is marked as deleted, revert the stock
            if (transaction.status == 'deleted' && productSnaps[i].data() != null) {
              var productMap = productSnaps[i].data() as Map<String, dynamic>;
              var product = ProductModel.fromJson(productMap);
              int revertedSold = product.sold - orderedProduct.quantity;
              trx.update(productRefs[i], {'sold': revertedSold});
            }
          }
        }

        var transactionRef = _firebaseFirestore.collection('Transaction').doc('${transaction.id}');
        trx.update(
          transactionRef,
          transaction.toJson()
            ..remove('orderedProducts')
            ..remove('createdBy'),
        );
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<void>> softDeleteTransaction(int id) async {
    try {
      // 1. Get ordered products FIRST (outside the transaction block)
      var orderedProductsQuery = await _firebaseFirestore
          .collection('OrderedProduct')
          .where('transactionId', isEqualTo: id)
          .get();

      var orderedProducts = orderedProductsQuery.docs.map((e) => OrderedProductModel.fromJson(e.data())).toList();

      await _firebaseFirestore.runTransaction((trx) async {
        List<DocumentSnapshot> productSnaps = [];
        List<DocumentReference> productRefs = [];

        for (var orderedProduct in orderedProducts) {
          var ref = _firebaseFirestore.collection('Product').doc('${orderedProduct.productId}');
          productRefs.add(ref);
          productSnaps.add(await trx.get(ref));
        }

        for (int i = 0; i < orderedProducts.length; i++) {
          if (productSnaps[i].data() != null) {
            var productMap = productSnaps[i].data() as Map<String, dynamic>;
            var product = ProductModel.fromJson(productMap);
            int revertedSold = product.sold - orderedProducts[i].quantity;
            trx.update(productRefs[i], {'sold': revertedSold});
          }
        }

        // Update the transaction status
        var transactionRef = _firebaseFirestore.collection('Transaction').doc('$id');
        trx.update(transactionRef, {
          'status': 'deleted',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int id) async {
    try {
      // Get ordered products FIRST (outside the transaction block)
      var orderedProductsQuery = await _firebaseFirestore
          .collection('OrderedProduct')
          .where('transactionId', isEqualTo: id)
          .get();

      var orderedProducts = orderedProductsQuery.docs.map((e) => OrderedProductModel.fromJson(e.data())).toList();

      await _firebaseFirestore.runTransaction((trx) async {
        List<DocumentSnapshot> productSnaps = [];
        List<DocumentReference> productRefs = [];

        for (var orderedProduct in orderedProducts) {
          var ref = _firebaseFirestore.collection('Product').doc('${orderedProduct.productId}');
          productRefs.add(ref);
          productSnaps.add(await trx.get(ref));
        }

        for (int i = 0; i < orderedProducts.length; i++) {
          if (productSnaps[i].data() != null) {
            var productMap = productSnaps[i].data() as Map<String, dynamic>;
            var product = ProductModel.fromJson(productMap);
            int revertedSold = product.sold - orderedProducts[i].quantity;
            trx.update(productRefs[i], {'sold': revertedSold});
          }
          
          var orderedProductRef = _firebaseFirestore.collection('OrderedProduct').doc('${orderedProducts[i].id}');
          trx.delete(orderedProductRef);
        }

        // Delete the transaction completely
        var transactionRef = _firebaseFirestore.collection('Transaction').doc('$id');
        trx.delete(transactionRef);
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<TransactionModel?>> getTransaction(int id) async {
    try {
      var rawTransaction = await _firebaseFirestore.collection('Transaction').doc('$id').get();
      if (rawTransaction.data() == null) return Result.success(data: null);

      var transactionMap = rawTransaction.data() as Map<String, dynamic>;
      var transaction = TransactionModel.fromJson(transactionMap);

      var rawOrderedProducts = await _firebaseFirestore
          .collection('OrderedProduct')
          .where('transactionId', isEqualTo: id)
          .get();

      var orderedProducts = rawOrderedProducts.docs.map((e) => OrderedProductModel.fromJson(e.data())).toList();

      var rawUser = await _firebaseFirestore.collection('User').doc(transaction.createdById).get();
      if (rawUser.data() == null) return Result.failure(error: 'User data not found');

      var userMap = rawUser.data() as Map<String, dynamic>;
      var user = UserModel.fromJson(userMap);

      transaction.orderedProducts = orderedProducts;
      transaction.createdBy = user;

      return Result.success(data: transaction);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getAllUserTransactions(String userId) async {
    try {
      var rawTransactions = await _firebaseFirestore
          .collection('Transaction')
          .where('createdById', isEqualTo: userId)
          .get();

      var transactions = rawTransactions.docs.map((e) => TransactionModel.fromJson(e.data())).toList();

      var rawUser = await _firebaseFirestore.collection('User').doc(userId).get();
      if (rawUser.data() == null) return Result.failure(error: 'User data not found');

      var userMap = rawUser.data() as Map<String, dynamic>;
      var user = UserModel.fromJson(userMap);

      for (var transaction in transactions) {
        var rawOrderedProducts = await _firebaseFirestore
            .collection('OrderedProduct')
            .where('transactionId', isEqualTo: transaction.id)
            .get();

        var orderedProducts = rawOrderedProducts.docs.map((e) => OrderedProductModel.fromJson(e.data())).toList();
        transaction.orderedProducts = orderedProducts;
        transaction.createdBy = user;
      }

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getUserTransactions(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      var query = _firebaseFirestore
          .collection('Transaction')
          .where('createdById', isEqualTo: userId)
          .orderBy(orderBy, descending: sortBy == 'DESC')
          .limit(limit);


      if (offset != null) {
        var temp = await _firebaseFirestore
            .collection('Transaction')
            .where('createdById', isEqualTo: userId)
            .orderBy(orderBy, descending: sortBy == 'DESC')
            .limit(offset)
            .get();

        DocumentSnapshot<Object?>? lastSnapshot = temp.docs.lastOrNull;

        if (lastSnapshot != null) {
          query = query.startAfterDocument(lastSnapshot);
        } else {
          return Result.success(data: []);
        }
      }

      var rawTransactions = await query.get();
      var transactions = rawTransactions.docs.map((e) => TransactionModel.fromJson(e.data())).toList();

      var rawUser = await _firebaseFirestore.collection('User').doc(userId).get();
      if (rawUser.data() == null) return Result.failure(error: 'User data not found');

      var userMap = rawUser.data() as Map<String, dynamic>;
      var user = UserModel.fromJson(userMap);

      for (var transaction in transactions) {
        var rawOrderedProducts = await _firebaseFirestore
            .collection('OrderedProduct')
            .where('transactionId', isEqualTo: transaction.id)
            .get();

        var orderedProducts = rawOrderedProducts.docs.map((e) => OrderedProductModel.fromJson(e.data())).toList();
        transaction.orderedProducts = orderedProducts;
        transaction.createdBy = user;
      }

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }
}