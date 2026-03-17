import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_cashier_app/domain/entities/product_entity.dart';
import 'package:pos_cashier_app/domain/entities/category_entity.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int id;

  const ProductDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        titleSpacing: 0,
        actions: [_EditButton(id: id)],
      ),
      body: FutureBuilder<ProductEntity?>(
        future: ref.read(productDetailControllerProvider).getProductDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppProgressIndicator();
          }

          if (snapshot.hasError) {
            throw snapshot.error.toString();
          }

          if (snapshot.data == null) {
            return const AppEmptyState(title: 'Produk Tidak Ditemukan');
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(imageUrl: product.imageUrl),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductName(
                        productName: product.name,
                        createdAt: product.createdAt,
                        updatedAt: product.updatedAt,
                      ),
                      _ProductCategory(categoryId: product.categoryId),
                      _ProductPrice(price: product.price),
                      _ProductAvailability(isAvailable: product.isAvailable),
                      _ProductSold(sold: product.sold),
                      _ProductDescription(description: product.description),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final int id;

  const _EditButton({required this.id});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              'Edit Produk',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () {
          context.push('/products/product-edit/$id');
        },
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: AppSizes.screenWidth(context),
        minHeight: AppSizes.screenHeight(context) / 3,
        maxHeight: AppSizes.screenHeight(context) / 3,
      ),
      child: AppImage(
        image: imageUrl ?? '',
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        enableFullScreenView: true,
        errorWidget: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.surfaceDim,
          size: 32,
        ),
      ),
    );
  }
}

class _ProductName extends StatelessWidget {
  final String? productName;
  final String? createdAt;
  final String? updatedAt;

  const _ProductName({
    required this.productName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName ?? '(Tanpa Nama)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          "Ditambahkan pada ${DateTimeFormatter.stripDateWithClock(createdAt ?? '')}",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          "Terakhir diubah ${DateTimeFormatter.stripDateWithClock(updatedAt ?? '')}",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ProductCategory extends ConsumerWidget {
  final int? categoryId;

  const _ProductCategory({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We look up the category name from the master list in your provider
    final categories = ref.watch(productsControllerProvider).categories;
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => CategoryEntity(name: 'Tanpa Kategori'),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kategori",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPrice extends StatelessWidget {
  final int? price;

  const _ProductPrice({required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Harga",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            CurrencyFormatter.format(price ?? 0),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Replaced _ProductStock with _ProductAvailability
class _ProductAvailability extends StatelessWidget {
  final bool isAvailable;

  const _ProductAvailability({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Status",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            isAvailable ? "Tersedia" : "Tidak Tersedia",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // Adds a nice visual cue: Primary color if available, Error color if not
              color: isAvailable ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSold extends StatelessWidget {
  final int? sold;

  const _ProductSold({required this.sold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Telah Terjual",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            "$sold",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDescription extends StatelessWidget {
  final String? description;

  const _ProductDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Deskripsi",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            description ?? '(Tidak ada deskripsi)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}