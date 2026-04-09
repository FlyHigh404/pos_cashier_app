import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'), 
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SESI KASIR AKTIF',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const _ActiveCashierInfo(),
            const _EndSessionButton(), // New button for Cashier Logout

            const SizedBox(height: AppSizes.padding * 2),
            const Divider(),

            Text(
              'Printer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),

            const _PrinterSettingsButton(),

            const SizedBox(height: AppSizes.padding),

            Text(
              'STATUS CLOUD & SINKRONISASI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),

            _SettingsListTile(
              icon: Icons.cloud_sync_rounded,
              title: 'Cadangkan Data',
              onTap: () => context.push('/account/sync-data'),
            ),
            
            const SizedBox(height: AppSizes.padding),
            
            Text(
              'PENGATURAN APLIKASI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            
            const _ManageCashiersButton(),
            const _ManageCategoriesButton(),
            
            const _ThemeButton(),
            const _AboutButton(),
            
            const SizedBox(height: AppSizes.padding * 2),
          ],
        ),
      ),
    );
  }
}

class _ActiveCashierInfo extends ConsumerWidget {
  const _ActiveCashierInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final activeCashierName = session.activeCashierName ?? 'Belum Ada Sesi';

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSizes.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasir Saat Ini:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                Text(
                  activeCashierName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _EndSessionButton extends ConsumerWidget {
  const _EndSessionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.errorContainer,
        textColor: Theme.of(context).colorScheme.error,
        text: 'Akhiri Shift / Ganti Kasir',
        onTap: () {
          AppDialog.show(
            title: 'Akhiri Shift?',
            text: 'Apakah Anda yakin ingin mengakhiri sesi kasir saat ini?',
            leftButtonText: 'Batal',
            rightButtonText: 'Akhiri Shift',
            onTapRightButton: (dialogContext) {
              dialogContext.pop(); // Tutup dialog
              
              ref.read(sessionControllerProvider).endSession();
              
              context.go('/session-select'); 
              
              AppSnackBar.show('Sesi kasir diakhiri.');
            },
          );
        },
      ),
    );
  }
}

class _ManageCashiersButton extends StatelessWidget {
  const _ManageCashiersButton();

  // The logic for the Hardcoded PIN Pop-Up
  void _showPinDialog(BuildContext context) {
    final pinController = TextEditingController();

    AppDialog.show(
      title: 'Akses Terkunci',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Masukkan PIN Admin untuk mengelola data kasir.'),
          const SizedBox(height: AppSizes.padding),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '****',
              counterText: '',
            ),
          ),
        ],
      ),
      leftButtonText: 'Batal',
      rightButtonText: 'Buka',
      onTapRightButton: (dialogContext) {
        if (pinController.text == '1234') {
          dialogContext.pop();
          context.go('/account/manage-cashiers'); 
          AppSnackBar.show('Akses Diberikan');
        } else {
          dialogContext.pop();
          AppSnackBar.showError('PIN Salah!');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsListTile(
      icon: Icons.people_alt_rounded,
      title: 'Kelola Data Kasir',
      onTap: () => _showPinDialog(context),
    );
  }
}

class _ManageCategoriesButton extends StatelessWidget {
  const _ManageCategoriesButton();

  @override
  Widget build(BuildContext context) {
    return _SettingsListTile(
      icon: Icons.category_outlined, 
      title: 'Kelola Kategori Menu',
      onTap: () {
        // You can change this to push if you want a back button instead of bottom nav replacement
        context.push('/account/manage-categories'); 
      },
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    return _SettingsListTile(
      icon: Icons.dark_mode_outlined,
      title: 'Tema Tampilan',
      onTap: () {
        AppDialog.show(
          title: 'Tema',
          leftButtonText: 'Tutup',
          child: const _ThemeDialogBody(),
        );
      },
    );
  }
}

class _PrinterSettingsButton extends StatelessWidget {
  const _PrinterSettingsButton();

  @override
  Widget build(BuildContext context) {
    return _SettingsListTile(
      icon: Icons.print_outlined,
      title: 'Pengaturan Printer',
      onTap: () => context.go('/account/printer-settings'),
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton();

  @override
  Widget build(BuildContext context) {
    return _SettingsListTile(
      icon: Icons.info_outline_rounded,
      title: 'Tentang Aplikasi',
      onTap: () => context.go('/account/about'),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsListTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSizes.padding),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeDialogBody extends ConsumerWidget {
  const _ThemeDialogBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(themeControllerProvider);

    return Row(
      children: [
        Switch(
          value: !provider.isLight(),
          onChanged: (val) {
            provider.changeBrightness(!val);
          },
        ),
        const SizedBox(width: AppSizes.padding),
        Text(
          'Mode Gelap',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}