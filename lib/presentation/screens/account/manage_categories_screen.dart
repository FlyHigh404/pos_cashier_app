import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories as soon as the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryControllerProvider).getCategories();
    });
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    AppDialog.show(
      title: 'Tambah Kategori Baru',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.padding),
        child: AppTextField(
          controller: nameController,
          labelText: 'Nama Kategori',
          hintText: 'Contoh: Makanan Berat...',
        ),
      ),
      leftButtonText: 'Batal',
      rightButtonText: 'Simpan',
      onTapRightButton: (dialogContext) async {
        final name = nameController.text.trim();
        if (name.isEmpty) {
          AppSnackBar.showError('Nama kategori tidak boleh kosong!');
          return;
        }

        dialogContext.pop(); // Close dialog immediately
        
        // Show loading spinner while the controller does the work
        await AppDialog.showProgress(() async {
          await ref.read(categoryControllerProvider).addCategory(name);
          return true; 
        });

        if (mounted) AppSnackBar.show('Kategori berhasil ditambahkan');
      },
    );
  }

  void _confirmDelete(int id, String name) {
    AppDialog.show(
      title: 'Hapus Kategori?',
      text: 'Apakah Anda yakin ingin menghapus kategori "$name"?',
      leftButtonText: 'Batal',
      rightButtonText: 'Hapus',
      rightButtonColor: Theme.of(context).colorScheme.errorContainer,
      rightButtonTextColor: Theme.of(context).colorScheme.error,
      onTapRightButton: (dialogContext) async {
        dialogContext.pop();
        
        // Show loading spinner while deleting
        await AppDialog.showProgress(() async {
          await ref.read(categoryControllerProvider).deleteCategory(id);
          return true;
        });

        if (mounted) AppSnackBar.show('Kategori berhasil dihapus');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the controller state
    final categoryState = ref.watch(categoryControllerProvider);
    final categories = categoryState.categories;
    final isLoading = categoryState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        elevation: 0,
      ),
      body: isLoading
          ? const AppProgressIndicator()
          : categories.isEmpty
              ? AppEmptyState(
                  title: 'Belum Ada Kategori',
                  subtitle: 'Silakan tambah kategori untuk mengelompokkan menu Anda.',
                  buttonText: 'Tambah Kategori',
                  onTapButton: _showAddCategoryDialog,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSizes.padding / 2),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppSizes.padding),
                              Text(
                                category.name,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            // Call the delete confirmation
                            onPressed: () => _confirmDelete(category.id!, category.name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Kategori'),
            )
          : null,
    );
  }
}