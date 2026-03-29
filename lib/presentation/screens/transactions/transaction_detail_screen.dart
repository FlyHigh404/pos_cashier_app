import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  const _BuildPrintButton({required this.onPressed});

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
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.print_rounded, size: 28),
          label: const Text(
            'CETAK STRUK',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, // 🚀 Disabled bg color
            disabledForegroundColor: Theme.of(context).colorScheme.outline, // 🚀 Disabled text color
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            elevation: onPressed == null ? 0 : 2, // Remove shadow when disabled
          ),
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
    // 🚀 Change UI based on whether it is deleted or not
    final isDeleted = status == 'deleted';

    return Column(
      children: [
        Icon(
          isDeleted ? Icons.cancel_rounded : Icons.check_circle_outline_rounded,
          color: isDeleted ? Theme.of(context).colorScheme.error : AppColors.green,
          size: 60,
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          isDeleted ? 'Transaksi Dibatalkan' : 'Transaksi Berhasil',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDeleted ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
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