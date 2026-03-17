import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_drop_down.dart';

class SessionSelectScreen extends ConsumerStatefulWidget {
  const SessionSelectScreen({super.key});

  @override
  ConsumerState<SessionSelectScreen> createState() => _SessionSelectScreenState();
}

class _SessionSelectScreenState extends ConsumerState<SessionSelectScreen> {
  String? _selectedCashier;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await ref.read(cashiersControllerProvider).fetchCashiers();
    
    final cashiers = ref.read(cashiersControllerProvider).allCashiers ?? [];
    if (cashiers.length == 1) {
      setState(() {
        _selectedCashier = cashiers.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashierProvider = ref.watch(cashiersControllerProvider);
    final cashiers = cashierProvider.allCashiers ?? [];
    final isLoading = cashierProvider.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius * 2),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.padding),
                  
                  // Title
                  Text(
                    'Mulai Sesi Kasir',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih nama Anda untuk memulai shift kerja.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: AppSizes.padding * 2),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (cashiers.isEmpty)
                    Text(
                      'Belum ada data kasir.\nSilakan login sebagai Admin dan tambahkan kasir di menu Pengaturan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                  else
                    AppDropDown(
                      labelText: 'Nama Kasir',
                      hintText: 'Pilih Kasir...',
                      selectedValue: _selectedCashier,
                      dropdownItems: cashiers.map((cashier) {
                        return DropdownMenuItem(
                          value: cashier.name, 
                          child: Row(
                            children: [
                              Icon(
                                cashier.name == 'Admin' 
                                    ? Icons.admin_panel_settings_rounded 
                                    : Icons.person_outline_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(cashier.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCashier = value;
                        });
                      },
                    ),
                  const SizedBox(height: AppSizes.padding * 2),

                  AppButton(
                    text: 'Mulai Shift',
                    enabled: _selectedCashier != null && !isLoading,
                    onTap: () async {
                      if (_selectedCashier == null) return;
                      await ref.read(sessionControllerProvider).startSession(_selectedCashier!);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}