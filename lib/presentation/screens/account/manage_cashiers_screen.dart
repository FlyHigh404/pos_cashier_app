import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';

class ManageCashiersScreen extends ConsumerStatefulWidget {
  const ManageCashiersScreen({super.key});

  @override
  ConsumerState<ManageCashiersScreen> createState() => _ManageCashiersScreenState();
}

class _ManageCashiersScreenState extends ConsumerState<ManageCashiersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashiersControllerProvider).fetchCashiers();
    });
  }

  void _showAddCashierDialog() {
    final nameController = TextEditingController();

    AppDialog.show(
      title: 'Tambah Kasir Baru',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Masukkan nama lengkap kasir baru:'),
          const SizedBox(height: AppSizes.padding),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Cth: Budi Santoso',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
      leftButtonText: 'Batal',
      rightButtonText: 'Simpan',
      onTapRightButton: (context) async {
        final name = nameController.text.trim();
        if (name.isEmpty) {
          AppSnackBar.showError('Nama kasir tidak boleh kosong!');
          return;
        }

        Navigator.pop(context); // Tutup dialog

        // Panggil fungsi Add di Provider
        final success = await ref.read(cashiersControllerProvider).addCashier(name);
        
        if (success) {
          AppSnackBar.show('Kasir "$name" berhasil ditambahkan!');
        } else {
          AppSnackBar.showError('Gagal menambahkan kasir.');
        }
      },
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    AppDialog.show(
      title: 'Hapus Kasir?',
      text: 'Apakah kamu yakin ingin menghapus "$name" dari daftar kasir? Transaksi lama tetap akan mencatat nama ini.',
      leftButtonText: 'Batal',
      rightButtonText: 'Hapus',
      onTapRightButton: (context) async {
        Navigator.pop(context); // Tutup dialog
        
        // Panggil fungsi Delete di Provider
        final success = await ref.read(cashiersControllerProvider).deleteCashier(id);
        
        if (success) {
          AppSnackBar.show('Kasir berhasil dihapus!');
        } else {
          AppSnackBar.showError('Gagal menghapus kasir.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantau perubahan data secara real-time!
    final provider = ref.watch(cashiersControllerProvider);
    final cashiers = provider.allCashiers ?? [];
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Kasir'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCashierDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kasir'),
      ),
      body: isLoading
          ? const AppProgressIndicator()
          : cashiers.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada kasir',
                  subtitle: 'Tekan tombol di bawah untuk menambah data kasir baru.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  itemCount: cashiers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cashier = cashiers[index]; // Ini sekarang adalah CashierEntity
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          cashier.name, // Memanggil properti name dari Entity
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        subtitle: const Text('Kasir Aktif'),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          // Memanggil ID dari Entity
                          onPressed: () => _showDeleteConfirmation(cashier.id ?? '', cashier.name),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}