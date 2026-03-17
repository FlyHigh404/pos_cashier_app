import 'package:flutter/foundation.dart';

import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_provider.dart';

class ProductsProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final ProductRepository productRepository;

  ProductsProvider({
    required this.authProvider,
    required this.productRepository,
  });

  List<ProductEntity>? allProducts;
  List<CategoryEntity> categories = [];
  
  int? selectedCategoryId;
  String _currentSearchQuery = '';
  bool isLoadingMore = false;

  void resetProducts() {
    allProducts = null;
    categories = [];
    selectedCategoryId = null;
    _currentSearchQuery = '';
    notifyListeners();
  }

  Future<void> selectCategory(int? categoryId) async {
    selectedCategoryId = categoryId;
    allProducts = null; 
    notifyListeners();
    await getAllProducts(); 
  }

  Future<void> searchProducts(String query) async {
    _currentSearchQuery = query;
    allProducts = null;
    notifyListeners();
    await getAllProducts();
  }

  Future<void> getAllProducts({bool isLoadMore = false}) async {
    var userId = authProvider.user?.id;
    if (userId == null) throw 'Unathenticated!';

    if (isLoadMore && isLoadingMore) return; 

    if (isLoadMore) {
      isLoadingMore = true;
      notifyListeners();
    } else {
      final categoryRes = await productRepository.getCategories();
      if (categoryRes.isSuccess) {
        categories = categoryRes.data ?? [];
      } else {
        categories = [];
      }
    }

    int? currentOffset = isLoadMore ? (allProducts?.length ?? 0) : null;
    var params = ProductParams(
      param: userId,
      offset: currentOffset,
      categoryId: selectedCategoryId, 
      contains: _currentSearchQuery,     
    );

    var res = await GetUserProductsUsecase(productRepository).call(params);

    if (res.isSuccess) {
      final newData = res.data ?? [];
      
      if (!isLoadMore) {
        allProducts = List.from(newData);
      } else {
        allProducts?.addAll(newData);
      }

      isLoadingMore = false;
      notifyListeners(); // Boom. Done. No more _applyFilters!
    } else {
      isLoadingMore = false;
      notifyListeners();
      throw Exception(res.error?.toString() ?? 'Failed to load data');
    }
  }
}