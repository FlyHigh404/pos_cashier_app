import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';

class SyncDataScreen extends ConsumerWidget {
  const SyncDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainProvider = ref.watch(mainControllerProvider);
    
    final isHasInternet = mainProvider.isHasInternet;
    final isSyncronizing = mainProvider.isSyncronizing;
    
    final isFullySynced = mainProvider.isHasQueuedActions;

    // Determine overall status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isHasInternet) {
      statusColor = Theme.of(context).colorScheme.error;
      statusIcon = Icons.wifi_off_rounded;
      statusText = 'OFFLINE';
    } else if (isSyncronizing) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.sync_rounded;
      statusText = 'MENYINKRONKAN...';
    } else if (!isFullySynced) {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.warning_rounded;
      statusText = 'DATA TERTUNDA';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.cloud_done_rounded;
      statusText = 'TERHUBUNG & AMAN';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadangkan Data'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.padding),
            
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                ),
                if (isSyncronizing)
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      color: statusColor,
                    ),
                  )
                else
                  Icon(statusIcon, size: 60, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSizes.padding * 2),
            Text(
              statusText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan data Anda selalu dicadangkan ke server untuk mencegah kehilangan data jika perangkat rusak.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            
            const SizedBox(height: AppSizes.padding * 3),
            
            _StatCard(
              title: 'Koneksi Internet',
              value: isHasInternet ? 'Terhubung' : 'Terputus',
              icon: isHasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              iconColor: isHasInternet ? Colors.green : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSizes.padding),
            _StatCard(
              title: 'Status Database Lokal',
              value: isFullySynced ? 'Semua Dicadangkan' : 'Menunggu Cadangan',
              icon: isFullySynced ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
              iconColor: isFullySynced ? Colors.green : Colors.orange.shade700,
            ),

            const SizedBox(height: AppSizes.padding * 2), // Extra padding at the bottom of the scroll
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                text: isSyncronizing ? 'Menyinkronkan Data...' : 'Mulai Pencadangan',
                enabled: isHasInternet && !isSyncronizing,
                buttonColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                onTap: () {
                  if (!isHasInternet) {
                    AppSnackBar.show('Tidak dapat mencadangkan saat offline.');
                    return;
                  }
                  ref.read(mainControllerProvider).checkAndSyncAllData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSizes.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}