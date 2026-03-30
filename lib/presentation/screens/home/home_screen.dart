import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/product_entity.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import 'components/menu_card.dart';
import 'components/cart_panel_body.dart';
import 'components/cart_panel_footer.dart';
import 'components/cart_panel_header.dart';
import 'components/order_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => onRefresh());
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
    final productProvider = ref.read(productsControllerProvider);

    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
      
      if (!productProvider.isLoadingMore && searchFieldController.text.isEmpty) {
        await productProvider.getAllProducts(isLoadMore: true);
      }
    }
  }

  Future<void> onRefresh() async {
    final productProvider = ref.read(productsControllerProvider);
    final mainProvider = ref.read(mainControllerProvider);

    await productProvider.getAllProducts();
    await mainProvider.checkIsHasQueuedActions();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = ref.read(homeControllerProvider);

    return Scaffold(
      body: SlidingUpPanel(
        controller: homeProvider.panelController,
        minHeight: 88,
        maxHeight: AppSizes.screenHeight(context) - AppSizes.appBarHeight() - AppSizes.viewPadding(context).top,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radius * 2),
          topRight: Radius.circular(AppSizes.radius * 2),
        ),
        body: _Body(
          scrollController: scrollController,
          searchFieldController: searchFieldController,
          onRefresh: onRefresh,
        ),
        header: const CartPanelHeader(),
        panel: const CartPanelBody(),
        footer: const CartPanelFooter(),
        onPanelOpened: () => homeProvider.onChangedIsPanelExpanded(true),
        onPanelClosed: () => homeProvider.onChangedIsPanelExpanded(false),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController searchFieldController;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.scrollController,
    required this.searchFieldController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsControllerProvider.select((p) => p.allProducts));
    final isLoadingMore = ref.watch(productsControllerProvider.select((p) => p.isLoadingMore));

    return Scaffold(
      appBar: AppBar(
        title: const _Title(),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: const [
          _SyncButton(),
          _NetworkInfo(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
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
              const SliverToBoxAdapter(
                child: _CategoryFilterBar(),
              ),
              SliverLayoutBuilder(
                builder: (context, constraint) {
                  if (allProducts == null) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 140),
                        child: AppProgressIndicator(),
                      ),
                    );
                  }

                  if (allProducts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 140),
                        child: AppEmptyState(
                          subtitle: 'Menu belum tersedia, silakan tambah menu untuk melanjutkan',
                          buttonText: 'Tambah Menu',
                          onTapButton: () => context.push('/products/product-create'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1 / 1.34,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: allProducts.length,
                      itemBuilder: (context, i) {
                        return _MenuCard(product: allProducts[i]);
                      },
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 140),
                sliver: SliverToBoxAdapter(
                  child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. Converted to a regular StatelessWidget and redesigned the UI
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/app_icon.png', // Uses your local launcher icon
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 32,
              height: 32,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.storefront_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kasir Bakso Idola',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              'Developed by FlyHigh Sinergi',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHasQueuedActions = ref.watch(mainControllerProvider.select((p) => p.isHasQueuedActions));
    final isSyncronizing = ref.watch(mainControllerProvider.select((p) => p.isSyncronizing));

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding / 4),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: isHasQueuedActions && !isSyncronizing
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Row(
          children: [
            Icon(
              isSyncronizing
                  ? Icons.sync
                  : isHasQueuedActions
                  ? Icons.cloud_done_sharp
                  : Icons.sync_problem_sharp,
              size: 12,
              color: isHasQueuedActions && !isSyncronizing
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: AppSizes.padding / 4),
          ],
        ),
        onTap: () {
          ref.read(mainControllerProvider).checkAndSyncAllData();
        },
      ),
    );
  }
}

class _NetworkInfo extends ConsumerWidget {
  const _NetworkInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHasInternet = ref.watch(mainControllerProvider.select((provider) => provider.isHasInternet));

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: isHasInternet
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Icon(
          isHasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 12,
          color: isHasInternet ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        ),
        onTap: () {
          AppSnackBar.show(isHasInternet ? 'Mode Online' : 'Tidak ada internet, berjalan pada mode offline');
        },
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
      hintText: 'Cari Menu...',
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
    final categories = ref.watch(productsControllerProvider.select((p) => p.categories));
    final selectedId = ref.watch(productsControllerProvider.select((p) => p.selectedCategoryId));
    final controller = ref.read(productsControllerProvider);

    // Hide the bar if categories haven't loaded yet to prevent UI jumping
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for "Semua" (All)
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
            side: BorderSide(
              color: isSelected 
                  ? Colors.transparent 
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
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

class _MenuCard extends ConsumerWidget {
  final ProductEntity product;

  const _MenuCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeProvider = ref.watch(homeControllerProvider);
    final cartItem = homeProvider.orderedProducts.where((item) => item.productId == product.id).firstOrNull;
    final currentQty = cartItem?.quantity ?? 0;

    return MenuCard(
      product: product,
      enabled: product.isAvailable == true,
      quantity: currentQty,

      onIncrement: () {
        ref.read(homeControllerProvider).onAddOrderedProduct(product, 1);
      },
      
      onDecrement: () {
        if (currentQty > 0) {
          ref.read(homeControllerProvider).onAddOrderedProduct(product, -1);
        }
      },
      onTap: () {
        if (currentQty == 0) {
          ref.read(homeControllerProvider).onAddOrderedProduct(product, 1);
        }
      },
      // onTap: () {
      //   final homeProvider = ref.read(homeControllerProvider);

      //   int inputQty = 1;

      //   AppDialog.show(
      //     title: 'Masukkan Jumlah',
      //     child: OrderCard(
      //       name: product.name,
      //       imageUrl: product.imageUrl,
      //       price: product.price,
      //       initialQuantity: inputQty,
      //       onChangedQuantity: (val) {
      //         inputQty = val;
      //       },
      //     ),
      //     rightButtonText: 'Tambah ke Keranjang',
      //     leftButtonText: 'Batal',
      //     onTapLeftButton: (context) {
      //       context.pop();
      //     },
      //     onTapRightButton: (context) {
      //       homeProvider.onAddOrderedProduct(product, inputQty);
      //       context.pop();
      //     },
      //   );
      // },
    );
  }
}