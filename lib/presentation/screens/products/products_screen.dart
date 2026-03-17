import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/product_entity.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';
import 'components/products_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsControllerProvider).getAllProducts();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchFieldController.dispose();
    super.dispose();
  }

  void scrollListener() async {
    // final productProvider = ref.read(productsControllerProvider);

    // if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
      
    //   if (!productProvider.isLoadingMore && searchFieldController.text.isEmpty) {
    //     await productProvider.getAllProducts(isLoadMore: true);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsControllerProvider.select((p) => p.allProducts));
    final isLoadingMore = ref.watch(productsControllerProvider.select((p) => p.isLoadingMore));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: const [_AddButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Clear search when pulling to refresh to show all new data
          searchFieldController.clear(); 
          await ref.read(productsControllerProvider).getAllProducts();
        },
        displacement: 60,
        child: Scrollbar(
          child: CustomScrollView(
            controller: scrollController,
            // Disable scroll when data is null or empty
            physics: (allProducts?.isEmpty ?? true) ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                collapsedHeight: 70,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: _SearchField(controller: searchFieldController),
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoryFilterBar(),
              ),
              SliverLayoutBuilder(
                builder: (context, _) {
                  if (allProducts == null) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: AppProgressIndicator(),
                    );
                  }

                  if (allProducts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        // If controller is NOT empty, it means search found nothing
                        subtitle: searchFieldController.text.isNotEmpty 
                            ? 'Produk "${searchFieldController.text}" tidak ditemukan'
                            : 'Belum ada produk, silakan tambah produk baru',
                        buttonText: searchFieldController.text.isNotEmpty ? 'Hapus Pencarian' : 'Tambah Produk',
                        onTapButton: () {
                          if (searchFieldController.text.isNotEmpty) {
                            searchFieldController.clear();
                            ref.read(productsControllerProvider).searchProducts('');
                          } else {
                            context.push('/products/product-create');
                          }
                        },
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1 / 1.5,
                        crossAxisSpacing: AppSizes.padding / 2,
                        mainAxisSpacing: AppSizes.padding / 2,
                      ),
                      itemCount: allProducts.length,
                      itemBuilder: (context, i) {
                        return _ProductCard(product: allProducts[i]);
                      },
                    ),
                  );
                },
              ),
              if (searchFieldController.text.isEmpty)
                SliverToBoxAdapter(
                  child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

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
              Icons.add,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSizes.padding / 2),
            Text(
              'Tambah Menu',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () => context.go('/products/product-create'),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productProvider = ref.read(productsControllerProvider);

    return AppTextField(
      controller: controller,
      hintText: 'Cari Produk...',
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onChanged: (val) {
        productProvider.searchProducts(val);
      },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        productProvider.searchProducts(controller.text);
      },
      onTapClearButton: () {
        controller.clear();
        productProvider.searchProducts('');
      },
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(productsControllerProvider.select((p) => p.categories)) ?? [];
    final selectedId = ref.watch(productsControllerProvider.select((p) => p.selectedCategoryId));
    final controller = ref.read(productsControllerProvider);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for "Semua"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final isSelected = isAll ? selectedId == null : selectedId == category?.id;

          return ChoiceChip(
            label: Text(isAll ? 'Semua' : category!.name),
            selected: isSelected,
            onSelected: (_) => controller.selectCategory(isAll ? null : category!.id),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductsCard(
      product: product,
      onTap: () => context.go('/products/product-detail/${product.id}'),
    );
  }
}
