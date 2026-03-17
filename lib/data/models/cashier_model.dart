import '../../domain/entities/cashier_entity.dart';

class CashierModel extends CashierEntity {
  const CashierModel({
    required super.id,
    required super.name,
    super.isAvailable = true,
    super.createdById,
    super.createdAt,
    super.updatedAt,
  });

  factory CashierModel.fromJson(Map<String, dynamic> json) {
    return CashierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isAvailable: json['is_active'] == 1 || json['is_active'] == true, 
      createdById: json['created_by_id'],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isAvailable ? 1 : 0, // Ubah key jadi is_active
      'created_by_id': createdById,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CashierModel.fromEntity(CashierEntity entity) {
    return CashierModel(
      id: entity.id,
      name: entity.name,
      isAvailable: entity.isAvailable,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CashierEntity toEntity() => CashierEntity(
        id: id,
        name: name,
        isAvailable: isAvailable,
        createdById: createdById,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}