import 'package:flutter/foundation.dart';

import '../../../domain/entities/category_entity.dart';
import '../../../domain/repositories/product_repository.dart';

class CategoryController extends ChangeNotifier {
  final ProductRepository repository;
  CategoryController(this.repository);

  List<CategoryEntity> categories = [];
  bool isLoading = false;

  Future<void> getCategories() async {
    isLoading = true;
    notifyListeners();
    
    final res = await repository.getCategories();
    
    if (res.isSuccess) {
      categories = res.data ?? [];
    } else {
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final newCategory = CategoryEntity(name: name);
    final res = await repository.createCategory(newCategory);
    
    if (res.isSuccess) {
      await getCategories(); // Refresh list
    }
  }

  Future<void> deleteCategory(int id) async {
    final res = await repository.deleteCategory(id);
    
    if (res.isSuccess) {
      categories.removeWhere((cat) => cat.id == id);
      notifyListeners();
    }
  }
}