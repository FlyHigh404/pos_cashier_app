import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int? id;
  final String name;

  const CategoryEntity({
    this.id,
    required this.name,
  });

  CategoryEntity copyWith({
    int? id,
    String? name,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}