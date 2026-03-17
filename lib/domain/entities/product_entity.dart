import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int? id;
  final int? categoryId; // This links to CategoryEntity.id
  final String createdById;
  final String name;
  final String imageUrl;
  final int? sold;
  final int price;
  final bool isAvailable;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  const ProductEntity({
    this.id,
    this.categoryId,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    this.sold,
    required this.isAvailable,
    required this.price,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  ProductEntity copyWith({
    int? id,
    int? categoryId,
    String? createdById,
    String? name,
    String? imageUrl,
    int? sold,
    bool? isAvailable,
    int? price,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      createdById: createdById ?? this.createdById,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      sold: sold ?? this.sold,
      isAvailable: isAvailable ?? this.isAvailable,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        createdById,
        name,
        imageUrl,
        sold,
        isAvailable,
        price,
        description,
        createdAt,
        updatedAt,
      ];
}