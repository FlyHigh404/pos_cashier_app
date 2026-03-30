import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../../core/utilities/pdf_report_service.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import 'components/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsControllerProvider).getAllTransactions();
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
    final transactionProvider = ref.read(transactionsControllerProvider);
    
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
      
      if (!transactionProvider.isLoadingMore &&
          transactionProvider.allTransactions != null &&
          transactionProvider.allTransactions!.isNotEmpty) {
            
        await transactionProvider.getAllTransactions(offset: transactionProvider.allTransactions!.length);
      }
    }
  }

  // Fungsi helper untuk mengelompokkan transaksi berdasarkan tanggal
  Map<String, List<TransactionEntity>> _groupTransactions(List<TransactionEntity> transactions) {
    Map<String, List<TransactionEntity>> grouped = {};
    for (var t in transactions) {
      // Ambil tanggal saja (YYYY-MM-DD) dari createdAt
      String date = t.createdAt!.split('T')[0]; 
      if (grouped[date] == null) grouped[date] = [];
      grouped[date]!.add(t);
    }
    return grouped;
  }

  // Fungsi untuk memunculkan Popup Pilihan Laporan
  void _showReportFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radius * 2)),
      ),
      builder: (context) => const _ReportFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsControllerProvider.select((p) => p.allTransactions));
    final isLoadingMore = ref.watch(transactionsControllerProvider.select((p) => p.isLoadingMore));

    // Hitung ringkasan
    final groupedData = _groupTransactions(allTransactions ?? []);
    final todayKey = DateTime.now().toString().split(' ')[0];
    final todayTransactions = groupedData[todayKey] ?? [];
    final todayRevenue = todayTransactions
        .where((t) => t.status != 'deleted')
        .fold(0, (sum, item) => sum + (item.totalAmount));
    final todaySuccessOrders = todayTransactions.where((t) => t.status != 'deleted').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          _GenerateReportButton(
            onTap: () => _showReportFilterDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsControllerProvider).getAllTransactions(),
        displacement: 60,
        child: Scrollbar(
          child: CustomScrollView(
            controller: scrollController,
            physics: (allTransactions?.isEmpty ?? true) ? const AlwaysScrollableScrollPhysics() : null,
            slivers: [
              // Summary card
              SliverToBoxAdapter(
                child: _TodaySummaryCard(
                  orderCount: todaySuccessOrders,
                  revenue: todayRevenue,
                ),
              ),

              // Daftar Riwayat Pembayaran
              if (allTransactions == null)
                const SliverFillRemaining(child: AppProgressIndicator())
              else if (allTransactions.isEmpty)
                const SliverFillRemaining(child: AppEmptyState(subtitle: 'Belum Ada Riwayat Pembayaran'))
              else
                ...groupedData.entries.map((entry) {
                  final date = entry.key;
                  final transactions = entry.value;
                  final dailyTotal = transactions
                      .where((t) => t.status != 'deleted')
                      .fold(0, (sum, item) => sum + (item.totalAmount));

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _DateHeader(
                          date: date,
                          count: transactions.length,
                          total: dailyTotal,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = transactions[index];
                              final isDeleted = transaction.status == 'deleted';
                              final isPending = transaction.status == 'pending';

                              return Opacity(
                                opacity: isDeleted ? 0.35 : 1.0,
                                child: Stack(
                                  children: [
                                    TransactionCard(transaction: transaction),
                                    
                                    if (isDeleted)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'BATAL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),

                                    if (isPending)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'PENDING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            childCount: transactions.length,
                          ),
                        ),
                      ),
                    ],
                  );
                }),

              SliverToBoxAdapter(
                child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// FIXED: Added onTap parameter and updated the UI to be bold and prominent
class _GenerateReportButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GenerateReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'LAPORAN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget Ringkasan Atas
class _TodaySummaryCard extends StatelessWidget {
  final int orderCount;
  final int revenue;

  const _TodaySummaryCard({required this.orderCount, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.padding),
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              ),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          _summaryItem(context, 'Pesanan Hari Ini', orderCount.toString(), Icons.receipt_long),
          Container(width: 1, height: 40, color: Theme.of(context).colorScheme.primary),
          _summaryItem(context, 'Total Pendapatan', CurrencyFormatter.format(revenue), Icons.payments),
        ],
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                label, 
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary, 
              fontWeight: FontWeight.bold, 
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Header Tanggal
class _DateHeader extends StatelessWidget {
  final String date; // Formatnya "YYYY-MM-DD"
  final int count;
  final int total;

  const _DateHeader({required this.date, required this.count, required this.total});

  // Fungsi internal untuk membuat tampilan tanggal lebih ramah pengguna
  String _formatDisplayDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      
      // Cek apakah hari ini atau kemarin agar lebih mudah dibaca
      if (dateStr == now.toString().split(' ')[0]) {
        return 'Hari Ini';
      }
      
      DateTime yesterday = now.subtract(const Duration(days: 1));
      if (dateStr == yesterday.toString().split(' ')[0]) {
        return 'Kemarin';
      }
      return DateTimeFormatter.normal(parsedDate.toString()); 
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding, AppSizes.padding, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDisplayDate(date), // Memanggil fungsi bantuan di atas
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Text(
            '$count Pesanan • ${CurrencyFormatter.format(total)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReportFilterSheet extends ConsumerWidget {
  const _ReportFilterSheet();

  // Fungsi untuk memproses pembuatan PDF
  void _processReport(BuildContext context, WidgetRef ref, DateTime startDate, DateTime endDate, String label) async {
    // FIXED: Use Navigator.pop instead of context.pop() for bottom sheets to avoid router conflicts
    Navigator.pop(context); 
    
    final allTransactions = ref.read(transactionsControllerProvider).allTransactions ?? [];
    
    final filteredTransactions = allTransactions.where((t) {
      if (t.createdAt == null || t.status == 'deleted') return false;
      try {
        final tDate = DateTime.parse(t.createdAt!);
        return tDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
                tDate.isBefore(endDate.add(const Duration(seconds: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    if (filteredTransactions.isEmpty) {
      AppSnackBar.show('Tidak ada transaksi pada periode $label.');
      return;
    }

    AppSnackBar.show('Sedang menyiapkan laporan "$label"...');
    try {
      await PdfReportService.generateAndOpenPdf(
        transactions: filteredTransactions,
        startDate: startDate,
        endDate: endDate,
        label: label,
      );
    } catch (e) {
      AppSnackBar.show('Gagal membuat laporan: $e');
    }
  }

  // Fungsi untuk memunculkan DatePicker Kustom
  Future<void> _pickCustomDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)), 
        end: now,
      ),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary, // Sesuaikan warna
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null && context.mounted) {
      // Pastikan endDate mencakup sampai jam 23:59:59 hari tersebut
      final start = pickedRange.start;
      final end = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59);
      
      _processReport(context, ref, start, end, 'Kustom');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // Normalisasi 'Hari Ini' mulai dari jam 00:00:00
    final todayStart = DateTime(now.year, now.month, now.day); 
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
              child: Text(
                'Unduh Laporan PDF',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildTile(
              context: context,
              icon: Icons.today,
              title: 'Hari Ini',
              onTap: () => _processReport(context, ref, todayStart, todayEnd, 'Hari Ini'),
            ),
            _buildTile(
              context: context,
              icon: Icons.history,
              title: 'Kemarin',
              onTap: () {
                final yesterdayStart = todayStart.subtract(const Duration(days: 1));
                final yesterdayEnd = todayEnd.subtract(const Duration(days: 1));
                _processReport(context, ref, yesterdayStart, yesterdayEnd, 'Kemarin');
              },
            ),
            _buildTile(
              context: context,
              icon: Icons.date_range,
              title: 'Minggu Ini',
              onTap: () {
                // Mengambil hari Senin minggu ini
                final startOfWeek = todayStart.subtract(Duration(days: todayStart.weekday - 1));
                _processReport(context, ref, startOfWeek, todayEnd, 'Minggu Ini');
              },
            ),
            _buildTile(
              context: context,
              icon: Icons.calendar_month,
              title: 'Bulan Ini',
              onTap: () {
                final startOfMonth = DateTime(now.year, now.month, 1);
                _processReport(context, ref, startOfMonth, todayEnd, 'Bulan Ini');
              },
            ),
            _buildTile(
              context: context,
              icon: Icons.calendar_today,
              title: 'Tahun Ini',
              onTap: () {
                final startOfYear = DateTime(now.year, 1, 1);
                _processReport(context, ref, startOfYear, todayEnd, 'Tahun Ini');
              },
            ),
            const Divider(),
            _buildTile(
              context: context,
              icon: Icons.edit_calendar,
              title: 'Pilih Tanggal Kustom...',
              onTap: () => _pickCustomDate(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.outline),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}