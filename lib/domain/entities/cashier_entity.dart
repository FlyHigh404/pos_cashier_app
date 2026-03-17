import 'package:equatable/equatable.dart';

class CashierEntity extends Equatable {
  final String? id;
  final String name;
  final bool isAvailable;
  final String? createdById;
  final String? createdAt;
  final String? updatedAt;

  const CashierEntity({
    this.id,
    required this.name,
    required this.isAvailable,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, isAvailable, createdById, createdAt, updatedAt];
}