import 'package:equatable/equatable.dart';

class ProductParams<T> extends Equatable {
  final T? param;
  final String orderBy;
  final String sortBy;
  final int limit;
  final int? offset;
  final String? contains;
  final int? categoryId;

  const ProductParams({
    this.param,
    this.orderBy = 'sold',
    this.sortBy = 'DESC',
    this.limit = 10000,
    this.offset,
    this.contains,
    this.categoryId,
  });

  @override
  List<Object> get props => [];
}

class TransParams<T> extends Equatable {
  final T? param;
  final String orderBy;
  final String sortBy;
  final int limit;
  final int? offset;
  final String? contains;
  final int? categoryId;

  const TransParams({
    this.param,
    this.orderBy = 'createdAt',
    this.sortBy = 'DESC',
    this.limit = 10000,
    this.offset,
    this.contains,
    this.categoryId,
  });

  @override
  List<Object> get props => [];
}