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

  Widget _buildShortcutButton(String label, int amount, HomeProvider provider) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _amountController.text = amount.toString();
          provider.onChangedReceivedAmount(amount);
          setState(() {}); // Updates the UI instantly
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
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
      ),
    );
  }

  //change
  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(homeControllerProvider);
    
    // Auto-calculate the change (kembalian)
    final int receivedAmount = int.tryParse(_amountController.text) ?? 0;
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
                // Safely removes dots, commas, spaces, or letters (like "Rp") 
                final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                provider.onChangedReceivedAmount(int.tryParse(cleanVal) ?? 0);
                setState(() {}); // Updates the Kembalian text dynamically
              },
              ),
          ),
        ),

        // Cash shortcuts
        if (!isQris)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildShortcutButton('Uang Pas', totalAmount, provider),
                const SizedBox(width: 6),
                _buildShortcutButton('20k', 20000, provider),
                const SizedBox(width: 6),
                _buildShortcutButton('50k', 50000, provider),
                const SizedBox(width: 6),
                _buildShortcutButton('100k', 100000, provider),
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
                onTap: () {
                  context.pop();
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