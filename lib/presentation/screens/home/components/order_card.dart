import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

class OrderCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int price;
  final int initialQuantity;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapRemove;
  final Function(int) onChangedQuantity;

  const OrderCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.initialQuantity = 0,
    this.onTapCard,
    this.onTapRemove,
    required this.onChangedQuantity,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  int quantity = 1;

  @override
  void initState() {
    quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: InkWell(
        onTap: widget.onTapCard,
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.padding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(widget.price),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/pcs',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Removed the "Stock: ${widget.stock}" text from here
                        Container(
                          height: 36,
                          constraints: const BoxConstraints(maxWidth: 112),
                          child: Stack(
                            children: [
                              AppButton(
                                width: double.infinity,
                                height: 30,
                                padding: EdgeInsets.zero,
                                buttonColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                borderColor: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  '$quantity',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              AppButton(
                                width: 30,
                                height: 30,
                                padding: EdgeInsets.zero,
                                buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  '-',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  if (quantity > 1) {
                                    quantity -= 1;
                                    setState(() {});
                                    widget.onChangedQuantity(quantity);
                                  }
                                },
                              ),
                              Positioned(
                                right: 0,
                                child: AppButton(
                                  width: 30,
                                  height: 30,
                                  padding: EdgeInsets.zero,
                                  buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Text(
                                    '+',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  onTap: () {
                                    // Removed the quantity < widget.stock limitation
                                    quantity += 1;
                                    setState(() {});
                                    widget.onChangedQuantity(quantity);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(width: 0.5, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3.5),
                      child: widget.imageUrl.isEmpty
                          ? Icon(
                              Icons.image,
                              color: Theme.of(context).colorScheme.surfaceDim,
                              size: 32,
                            )
                          : widget.imageUrl!.startsWith('http')
                            ? CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
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
                              File(widget.imageUrl!), // Loads the local offline image perfectly!
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                color: Theme.of(context).colorScheme.surfaceDim,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.onTapRemove != null)
                    AppButton(
                      text: 'Hapus',
                      width: 70,
                      fontSize: 10,
                      borderRadius: BorderRadius.circular(4),
                      padding: const EdgeInsets.all(AppSizes.padding / 4),
                      buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.32),
                      textColor: Theme.of(context).colorScheme.error,
                      onTap: () {
                        AppDialog.show(
                          title: 'Konfirmasi',
                          text: 'Yakin untuk menghapus produk ini?',
                          rightButtonText: 'Hapus',
                          leftButtonText: 'Batal',
                          onTapRightButton: (context) {
                            widget.onTapRemove!();
                            context.pop();
                          },
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}