import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int id;

  const TransactionDetailScreen({super.key, required this.id});

  void _voidTransaction(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: const Text(
          'Transaksi ini akan dibatalkan dan pembayaran akan dianggap tidak valid. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memproses pembatalan...')),
    );
    final controller = ref.read(transactionDetailControllerProvider);
    final result = await controller.softDeleteTransaction(id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dibatalkan'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Refresh the screen data to show the new 'deleted' status
      controller.getTransactionDetail(id); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan transaksi: ${result.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _hardDeleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text(
          'Transaksi ini akan dihapus secara permanen dari sistem dan tidak dapat dikembalikan. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memproses penghapusan permanen...')),
    );
    final controller = ref.read(transactionDetailControllerProvider);
    
    final result = await controller.deleteTransaction(id); 

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus permanen'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus transaksi: ${result.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _print(BuildContext context, WidgetRef ref) async {
    final transaction = ref.read(transactionDetailControllerProvider).currentTransaction;
    if (transaction == null) return;

    final printerService = ref.read(printerServiceProvider);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (printerService.selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer belum dipilih! Silakan atur di menu Pengaturan.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; 
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menghubungkan ke printer & mencetak...'),
        duration: Duration(seconds: 1), // Persingkat durasi loading
      ),
    );

    final result = await printerService.printTransaction(transaction);

    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak: ${result.error}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5), // Beri waktu lebih lama agar terbaca
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        if (transaction.status == 'pending') {
          await ref.read(transactionDetailControllerProvider).markAsSuccess(transaction);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dicetak!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTransaction = ref.watch(transactionDetailControllerProvider).currentTransaction;
    final isDeleted = currentTransaction?.status == 'deleted';
    final isPending = currentTransaction?.status == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'), // Diubah ke Bahasa Indonesia
        elevation: 0,
      ),
      body: FutureBuilder<TransactionEntity?>(
        future: ref.read(transactionDetailControllerProvider).getTransactionDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppProgressIndicator();
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.data == null) {
            return const AppEmptyState(title: 'Data Tidak Ditemukan');
          }

          final transaction = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              children: [
                _StatusSection(status: transaction.status),
                const SizedBox(height: AppSizes.padding * 2),
                if (transaction.status == 'deleted')
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.padding),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.error),
                    ),
                    child: Text(
                      'TRANSAKSI INI TELAH DIBATALKAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _TransactionDetail(transaction: transaction),
                const SizedBox(height: AppSizes.padding),
                _PaymentDetail(transaction: transaction),
                const SizedBox(height: AppSizes.padding),
                if (transaction.status != 'deleted')
                  AppButton(
                    text: 'Batalkan Transaksi',
                    textColor: Theme.of(context).colorScheme.error,
                    buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderColor: Colors.transparent,
                    onTap: () => _voidTransaction(context, ref),
                  )
                else
                  AppButton(
                    text: 'Hapus Permanen Data Transaksi',
                    textColor: Colors.white,
                    buttonColor: Theme.of(context).colorScheme.error,
                    borderColor: Colors.transparent,
                    onTap: () => _hardDeleteTransaction(context, ref),
                  ),
                  
                const SizedBox(height: AppSizes.padding * 2),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: currentTransaction == null
          ? null 
          : _BuildPrintButton(
              isPending: isPending,
              onPressed: isDeleted ? null : () async {
                final bool? confirm = await _showConfirmDialog(context);
                if (confirm == true) {
                  _print(context, ref);
                }
              },
            ),
      );
  }
  
  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah yakin mau print struk?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );
  }
}

class _BuildPrintButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPending;

  const _BuildPrintButton({required this.onPressed, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ), 
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents taking up whole screen
          children: [
            if (isPending)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.padding),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.orange.shade700.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Klik tombol di bawah untuk cetak struk & selesaikan transaksi.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.print_rounded, size: 28),
              label: Text(
                isPending ? 'CETAK SEKARANG' : 'CETAK ULANG STRUK', // Dynamic label
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                disabledForegroundColor: Theme.of(context).colorScheme.outline, 
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                elevation: onPressed == null ? 0 : 2, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final String? status;

  const _StatusSection({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDeleted = status == 'deleted';
    final isPending = status == 'pending';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? hintText;

    if (isDeleted) {
      statusColor = Theme.of(context).colorScheme.error;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Transaksi Dibatalkan';
    } else if (isPending) {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.print_rounded;
      statusText = 'Menunggu Dicetak';
      hintText = 'Pencetakan struk diperlukan untuk\nmenyelesaikan transaksi ini.';
    } else {
      statusColor = AppColors.green;
      statusIcon = Icons.check_circle_outline_rounded;
      statusText = 'Transaksi Berhasil';
    }

    return Column(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 60,
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
        ),
        if (hintText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              hintText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID Transaksi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${transaction.id ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metode Pembayaran',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.paymentMethod.toLowerCase() == 'cash'
                    ? 'Tunai'
                    : transaction.paymentMethod.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kasir', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                transaction.cashierName?? 'Admin',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waktu Transaksi',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                DateTimeFormatter.normalWithClock(transaction.createdAt ?? ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nama Pelanggan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.customerName ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keterangan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.description ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  final TransactionEntity transaction;

  const _PaymentDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${transaction.orderedProducts?.length ?? '0'} Menu', // Ditambah kata 'Menu'
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(height: AppSizes.padding * 2),
          ...List.generate(transaction.orderedProducts?.length ?? 0, (i) {
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : AppSizes.padding / 2),
              child: _ProductItem(order: transaction.orderedProducts![i]),
            );
          }),
          const Divider(height: AppSizes.padding * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Harga',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                CurrencyFormatter.format(transaction.totalAmount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uang Diterima', // Diubah ke Bahasa Indonesia
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                CurrencyFormatter.format(transaction.receivedAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kembalian',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                CurrencyFormatter.format(transaction.receivedAmount - transaction.totalAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final OrderedProductEntity order;

  const _ProductItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${CurrencyFormatter.format(order.price)} x ${order.quantity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              CurrencyFormatter.format((order.price) * order.quantity),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}