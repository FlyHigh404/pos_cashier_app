import '../../domain/entities/ordered_product_entity.dart';

class OrderedProductModel {
  int id;
  int transactionId;
  int productId;
  int quantity;
  String name;
  String imageUrl;
  int price;
  String? createdAt;
  String? updatedAt;

  OrderedProductModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderedProductModel.fromJson(Map<String, dynamic> json) {
    return OrderedProductModel(
      id: json['id'],
      transactionId: json['transactionId'],
      productId: json['productId'],
      quantity: json['quantity'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      price: json['price'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'quantity': quantity,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory OrderedProductModel.fromEntity(OrderedProductEntity entity) {
    return OrderedProductModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      transactionId: entity.transactionId ?? DateTime.now().millisecondsSinceEpoch,
      productId: entity.productId,
      quantity: entity.quantity,
      name: entity.name,
      imageUrl: entity.imageUrl,
      price: entity.price,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  OrderedProductEntity toEntity() {
    return OrderedProductEntity(
      id: id,
      transactionId: transactionId,
      productId: productId,
      quantity: quantity,
      name: name,
      imageUrl: imageUrl,
      price: price,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
