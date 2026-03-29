import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? id;

  const ProductFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productFormProvider = ref.read(productFormControllerProvider);
      await productFormProvider.initProductForm(widget.id);

      nameController.text = productFormProvider.name ?? '';
      priceController.text = productFormProvider.price?.toString() ?? '';
      descController.text = productFormProvider.description ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
    super.dispose();
  }

  void onTapImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });
    
    try{
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // This helps avoid Firebase upload timeouts
      );

      if (pickedFile == null) return;

      // Crop the image to a 1:1 ratio (standard for product menus)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Gambar',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Potong Gambar'),
        ],
      );

      if (croppedFile != null) {
        // Update the provider with the new file
        ref.read(productFormControllerProvider).onChangedImage(File(croppedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void createProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormControllerProvider).createProduct();
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSnackBar.show('Product created');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void updatedProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormControllerProvider).updatedProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSnackBar.show('Product updated');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void deleteProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormControllerProvider).deleteProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSnackBar.show('Product deleted');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.read(productFormControllerProvider);

    final isLoaded = ref.watch(productFormControllerProvider.select((provider) => provider.isLoaded));
    final isAvailable = ref.watch(productFormControllerProvider.select((p) => p.isAvailable ?? true));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Tambah Menu' : 'Edit Menu'),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImageSection(onTapImage: onTapImage),
                  _NameField(
                    controller: nameController,
                    onChanged: provider.onChangedName,
                  ),
                  _PriceField(
                    controller: priceController,
                    onChanged: provider.onChangedPrice,
                  ),
                  _CategoryDropdown(),
                  _AvailabilitySwitch(
                    value: isAvailable,
                    onChanged: provider.onChangedIsAvailable,
                  ),
                  _DescriptionField(
                    controller: descController,
                    onChanged: provider.onChangedDesc,
                  ),
                  _CreateOrUpdateButton(
                    id: widget.id,
                    onCreateProduct: createProduct,
                    onUpdatedProduct: updatedProduct,
                  ),
                  _DeleteButton(
                    id: widget.id,
                    onDeleteProduct: deleteProduct,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ImageSection extends ConsumerWidget {
  final VoidCallback onTapImage;

  const _ImageSection({required this.onTapImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(productFormControllerProvider);
    final imageFile = provider.imageFile;
    final imageUrl = provider.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambar Menu',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Stack(
          children: [
            GestureDetector(
              onTap: onTapImage,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius - 1),
                    child: imageFile != null
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                          )
                        : (imageUrl != null && imageUrl.isNotEmpty)
                            ? (imageUrl.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.image_not_supported,
                                      color: Theme.of(context).colorScheme.surfaceDim,
                                      size: 40,
                                    ),
                                  )
                                : Image.file(
                                    File(imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.broken_image,
                                      color: Theme.of(context).colorScheme.surfaceDim,
                                      size: 40,
                                    ),
                                  ))
                            : Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Theme.of(context).colorScheme.outlineVariant,
                                size: 48,
                              ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: AppIconButton(
                icon: Icons.camera_alt_rounded,
                iconSize: 18,
                borderRadius: 8,
                padding: const EdgeInsets.all(8),
                onTap: onTapImage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: 'Nama',
        hintText: 'Contoh; Paket Bakso Asik...',
        onChanged: onChanged,
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PriceField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: 'Harga',
        hintText: 'Contoh: 10000...',
        type: AppTextFieldType.currency,
        onChanged: onChanged,
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(productsControllerProvider.select((p) => p.categories)) ?? [];
    final selectedId = ref.watch(productFormControllerProvider.select((p) => p.categoryId));
    final formController = ref.read(productFormControllerProvider);

    final isSelectedIdValid = categories.any((cat) => cat.id == selectedId);
    final safeSelectedId = isSelectedIdValid ? selectedId : null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          DropdownButtonFormField<int>(
            value: safeSelectedId,
            hint: const Text('Pilih Kategori'),
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            items: categories.map((category) {
              return DropdownMenuItem<int>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                formController.onChangedCategory(val);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilitySwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu Tersedia?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DescriptionField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: 'Deskripsi',
        hintText: 'Deskripsi Produk (Opsional)...',
        maxLines: 4,
        onChanged: onChanged,
      ),
    );
  }
}

class _CreateOrUpdateButton extends ConsumerWidget {
  final int? id;
  final VoidCallback onCreateProduct;
  final VoidCallback onUpdatedProduct;

  const _CreateOrUpdateButton({
    required this.id,
    required this.onCreateProduct,
    required this.onUpdatedProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(productFormControllerProvider);
    final isFormValid = provider.isFormValid();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding * 1.5),
      child: AppButton(
        text: id == null ? 'Tambah Produk' : 'Simpan Perubahan',
        enabled: isFormValid,
        onTap: () {
          if (id != null) {
            onUpdatedProduct();
          } else {
            onCreateProduct();
          }
        },
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final int? id;
  final VoidCallback onDeleteProduct;

  const _DeleteButton({
    required this.id,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (id == null) return const SizedBox(height: AppSizes.padding * 2);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.padding,
        bottom: AppSizes.padding * 2,
      ),
      child: AppButton(
        text: 'Hapus Produk',
        textColor: Theme.of(context).colorScheme.error,
        buttonColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        onTap: () {
          AppDialog.show(
            title: 'Konfirmasi',
            text: 'Apakah anda yakin untuk menghapus produk ini?',
            leftButtonText: 'Batal',
            rightButtonText: 'Hapus',
            rightButtonColor: Theme.of(context).colorScheme.errorContainer,
            rightButtonTextColor: Theme.of(context).colorScheme.error,
            onTapRightButton: (context) async {
              context.pop();
              onDeleteProduct();
            },
          );
        },
      ),
    );
  }
}