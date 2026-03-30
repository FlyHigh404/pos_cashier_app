import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../providers/home/home_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_drop_down.dart';
import '../../../widgets/app_text_field.dart';

class CartPanelFooter extends ConsumerWidget {
  const CartPanelFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPanelExpanded = ref.watch(homeControllerProvider.select((provider) => provider.isPanelExpanded));

    return Container(
      width: AppSizes.screenWidth(context),
      padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          AnimatedContainer(
            width: isPanelExpanded ? AppSizes.screenWidth(context) / 3 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: AppSizes.screenWidth(context) / 3 - AppSizes.padding / 2,
                child: const _BackButton(),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: _PayButton(),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends ConsumerWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeProvider = ref.read(homeControllerProvider);

    return AppButton(
      text: 'Kembali',
      buttonColor: Theme.of(context).colorScheme.surface,
      borderColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.primary,
      onTap: () {
        homeProvider.onChangedIsPanelExpanded(false);
        homeProvider.panelController.close();
      },
    );
  }
}

class _PayButton extends ConsumerWidget {
  const _PayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(homeControllerProvider);

    return AppButton(
      text: !provider.isPanelExpanded
          ? provider.orderedProducts.isNotEmpty
              ? "${provider.orderedProducts.length} Item = ${CurrencyFormatter.format(provider.getTotalAmount())}"
              : 'Keranjang'
          : 'Bayar',
      enabled: provider.orderedProducts.isNotEmpty,
      onTap: () {
        if (provider.isPanelExpanded) {
          AppDialog.show(
            child: const _AdditionalInfoDialog(),
            showButtons: false,
            dismissible: false,
          );
        } else {
          /// Expands cart panel
          provider.onChangedIsPanelExpanded(!provider.isPanelExpanded);

          if (!provider.isPanelExpanded) {
            provider.panelController.close();
          } else {
            provider.panelController.open();
          }
        }
      },
    );
  }
}

class _AdditionalInfoDialog extends ConsumerStatefulWidget {
  const _AdditionalInfoDialog();

  @override
  ConsumerState<_AdditionalInfoDialog> createState() => _AdditionalInfoDialogState();
}

class _AdditionalInfoDialogState extends ConsumerState<_AdditionalInfoDialog> {
  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isQrisConfirmed = false;

  // track cash shortcuts tabs
  final Map<int, int> _shortcutCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(homeControllerProvider);
      
      // Auto-fill QRIS amount if it's the default selected method
      if (provider.selectedPaymentMethod == 'qris') {
        _amountController.text = provider.getTotalAmount().toString();
        provider.onChangedReceivedAmount(provider.getTotalAmount());
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> onPay({
    required GoRouter router,
    required HomeProvider homeProvider,
  }) async {
    var res = await AppDialog.showProgress(() {
      return homeProvider.createTransaction();
    });

    if (res.isSuccess) {
      router.go('/transactions/transaction-detail/${res.data}');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  Widget _buildShortcutButton(String label, int amount, HomeProvider provider, {bool isUangPas = false}) {
    final count = _shortcutCounts[amount] ?? 0;

    return Expanded(
      child: InkWell(
        onTap: () {
          int newAmount;

          if (isUangPas) {
            newAmount = amount;
            _shortcutCounts.clear(); // Reset all counters if Uang Pas is tapped
          } else {
            final currentAmount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            newAmount = currentAmount + amount;
            _shortcutCounts[amount] = count + 1; // Increment the specific button counter
          }

          _amountController.text = newAmount.toString();
          provider.onChangedReceivedAmount(newAmount);
          setState(() {}); 
        },
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                // Change color slightly if it has been tapped!
                color: count > 0 
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border.all(
                    color: count > 0 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outlineVariant, 
                    width: count > 0 ? 1 : 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            // Show counter
            if (count > 0 && !isUangPas)
              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'x$count',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //change
  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(homeControllerProvider);
    
    // Auto-calculate the change (kembalian)
    final int receivedAmount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final int totalAmount = provider.getTotalAmount();
    final int kembalian = (receivedAmount - totalAmount) > 0 ? (receivedAmount - totalAmount) : 0;
    
    final bool isQris = provider.selectedPaymentMethod == 'qris';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Total Pembayaran',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.padding),

        AppDropDown(
          labelText: 'Metode Pembayaran',
          selectedValue: provider.selectedPaymentMethod,
          dropdownItems: const [
            DropdownMenuItem(
              value: 'cash',
              child: Text('Tunai (Cash)'),
            ),
            DropdownMenuItem(
              value: 'qris',
              child: Text('QRIS'),
            ),
          ],
          onChanged: (v) {
            provider.onChangedPaymentMethod(v);
            if (v == 'qris') {
              // Lock the amount to the total for QRIS
              _amountController.text = totalAmount.toString();
              provider.onChangedReceivedAmount(totalAmount);
            } else {
              // Clear the amount so cashier can type the cash received
              _amountController.clear();
              provider.onChangedReceivedAmount(0);
            }
            _isQrisConfirmed = false; //reset qris change back to false on change
            setState(() {}); // Re-render to show updated kembalian
          },
        ),
        const SizedBox(height: AppSizes.padding),
        
        // Wrap with IgnorePointer to disable editing if QRIS is selected
        IgnorePointer(
          ignoring: isQris,
          child: Opacity(
            opacity: isQris ? 0.6 : 1.0,
            child:
              AppTextField(
              autofocus: false,
              keyboardType: TextInputType.number,
              type: AppTextFieldType.currency, 
              controller: _amountController,
              labelText: 'Jumlah Terima',
              hintText: 'Jumlah uang tunai yang diterima...',
              onChanged: (val) {
                final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                provider.onChangedReceivedAmount(int.tryParse(cleanVal) ?? 0);
                setState(() {});
              },
              ),
          ),
        ),

        // Cash shortcuts
        if (!isQris)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pintasan Uang Tunai',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _amountController.clear();
                          provider.onChangedReceivedAmount(0);
                          _shortcutCounts.clear();
                          setState(() {}); 
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          child: Text(
                            'Ulangi',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildShortcutButton('Uang Pas', totalAmount, provider, isUangPas: true),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildShortcutButton('Rp 500', 500, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 1 ribu', 1000, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 2 ribu', 2000, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 5 ribu', 5000, provider),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildShortcutButton('Rp 10 ribu', 10000, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 20 ribu', 20000, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 50 rb', 50000, provider),
                    const SizedBox(width: 6),
                    _buildShortcutButton('Rp 100 rb', 100000, provider),
                  ],
                ),
              ],
            ),
          ),
        
        // feedback
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0, right: 4.0),
          child: isQris
              // IF QRIS: Show confirmation switch
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pembayaran Terkonfirmasi?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isQrisConfirmed ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Switch(
                      value: _isQrisConfirmed,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _isQrisConfirmed = value;
                        });
                      },
                    ),
                  ],
                )

              // ELSE: Show Kembalian OR Warning
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      receivedAmount < totalAmount && receivedAmount > 0 
                          ? 'Uang Kurang:' 
                          : 'Kembalian:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: receivedAmount < totalAmount && receivedAmount > 0 
                            ? Theme.of(context).colorScheme.error 
                            : Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      receivedAmount < totalAmount && receivedAmount > 0 
                          ? CurrencyFormatter.format(totalAmount - receivedAmount) // Show how much they are short
                          : CurrencyFormatter.format(kembalian), // Show change
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: receivedAmount < totalAmount && receivedAmount > 0 
                            ? Theme.of(context).colorScheme.error 
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: AppSizes.padding / 2),
        AppTextField(
          controller: _customerController,
          labelText: 'Nama Pelanggan (Opsional)',
          hintText: 'Contoh: Budi',
          onChanged: (v) => provider.onChangedCustomerName(v),
        ),
        const SizedBox(height: AppSizes.padding),
        AppTextField(
          controller: _descriptionController,
          labelText: 'Keterangan (Opsional)',
          hintText: 'Catatan tambahan...',
          onChanged: (v) => provider.onChangedDescription(v),
        ),
        const SizedBox(height: AppSizes.padding * 1.5),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Batal',
                buttonColor: Theme.of(context).colorScheme.errorContainer,
                borderColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Batalkan Pembayaran?'),
                      content: const Text('Input nominal pembayaran akan direset. Apakah Anda yakin?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Ya, Batal', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    context.pop();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSizes.padding / 2),
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Struk',
                enabled: isQris ? _isQrisConfirmed : (receivedAmount >= totalAmount),
                onTap: () {
                  final homeProvider = ref.read(homeControllerProvider);
                  final router = ref.read(appRoutesProvider).router;

                  context.pop();
                  onPay(
                    homeProvider: homeProvider,
                    router: router,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}