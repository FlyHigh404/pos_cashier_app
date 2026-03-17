import 'package:equatable/equatable.dart';

class OrderedProductEntity extends Equatable {
  final int? id;
  final int? transactionId;
  final int productId;
  final int quantity;
  final String name;
  final String imageUrl;
  final int price;
  final String? createdAt;
  final String? updatedAt;

  const OrderedProductEntity({
    this.id,
    this.transactionId,
    required this.productId,
    required this.quantity,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  OrderedProductEntity copyWith({
    int? id,
    int? transactionId,
    int? productId,
    int? quantity,
    String? name,
    String? imageUrl,
    int? price,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderedProductEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionId,
    productId,
    quantity,
    name,
    imageUrl,
    price,
    createdAt,
    updatedAt,
  ];
}
