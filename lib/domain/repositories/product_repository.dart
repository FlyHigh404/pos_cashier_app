import '../../core/common/result.dart';
import '../entities/product_entity.dart';
import '../entities/category_entity.dart';

abstract class ProductRepository {
  Future<Result<int>> syncAllUserProducts(String userId);

  Future<Result<ProductEntity?>> getProduct(int productId);

  Future<List<ProductEntity>> getProducts({int? categoryId});
  Future<Result<List<CategoryEntity>>> getCategories();
  Future<Result<int>> createCategory(CategoryEntity category);
  Future<Result<void>> deleteCategory(int id);

  Future<Result<int>> createProduct(ProductEntity product);

  Future<Result<void>> updateProduct(ProductEntity product);

  Future<Result<void>> deleteProduct(int productId);

  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy,
    String sortBy,
    int limit,
    int? offset,
    String? contains,
    int? categoryId,
  });
}
