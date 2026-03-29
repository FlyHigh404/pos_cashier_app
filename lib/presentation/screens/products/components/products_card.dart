import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/product_entity.dart';

class ProductsCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final bool enabled;

  const ProductsCard({
    super.key,
    required this.product,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canTap = enabled;

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: InkWell(
          onTap: canTap ? onTap : null,
          splashColor: Colors.black.withValues(alpha: 0.06),
          splashFactory: InkRipple.splashFactory,
          highlightColor: Colors.black12,
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            padding: const EdgeInsets.all(
              8,
            ), // Tighter padding for a cleaner look
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Lets the card fit its contents naturally
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image & Out of Stock Overlay
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                            border: Border.all(
                              width: 0.5,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                              ? Icon(
                                  Icons.image,
                                  color: Theme.of(context).colorScheme.surfaceDim,
                                  size: 32,
                                )
                              : product.imageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.image_not_supported,
                                      color: Theme.of(context).colorScheme.surfaceDim,
                                      size: 32,
                                    ),
                                  )
                                : Image.file(
                                  File(product.imageUrl!), // Loads the local offline image perfectly!
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    color: Theme.of(context).colorScheme.surfaceDim,
                                    size: 32,
                                  ),
                                ),
                          ),
                      ),
                    ),
                    if (!product.isAvailable) const _OutOfStock(),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: product.isAvailable
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.outline, // Dims text if unavailable
                  ),
                ),
                const SizedBox(height: 6),

                // Price & Add Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        CurrencyFormatter.format(product.price),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: product.isAvailable
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutOfStock extends StatelessWidget {
  const _OutOfStock();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.padding / 4,
            horizontal: AppSizes.padding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Produk Kosong',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
