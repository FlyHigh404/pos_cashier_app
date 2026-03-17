import '../../domain/entities/product_entity.dart';

class ProductModel {
  int id;
  int? categoryId;
  String createdById;
  String name;
  String imageUrl;
  bool isAvailable;
  int sold;
  int price;
  String? description;
  String? createdAt;
  String? updatedAt;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    required this.isAvailable,
    required this.sold,
    required this.price,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['categoryId'],
      createdById: json['createdById'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 1,
      sold: json['sold'],
      price: json['price'],
      description: json['description'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'createdById': createdById,
      'name': name,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'sold': sold,
      'price': price,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      categoryId: entity.categoryId,
      createdById: entity.createdById,
      name: entity.name,
      imageUrl: entity.imageUrl,
      isAvailable: entity.isAvailable,
      sold: entity.sold ?? 0,
      price: entity.price,
      description: entity.description,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      categoryId: categoryId,
      createdById: createdById,
      name: name,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      sold: sold,
      price: price,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
