import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea( // Ditambahkan agar aman dari poni/notch HP modern
        child: Padding(
          padding: EdgeInsets.all(AppSizes.padding),
          child: Column(
            children: [
              _WelcomeMessage(),
              _SignInButton(),
              SizedBox(height: AppSizes.padding * 1.5), // Jarak sebelum footer
              _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320), // Disesuaikan dengan WelcomeScreen
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppImage(
              image: Assets.welcome,
              imgProvider: ImgProvider.assetImage,
              width: 180, // Ukuran gambar dibuat seragam
            ),
            const SizedBox(height: AppSizes.padding * 1.5),
            Text(
              'Halo!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary, // Warna utama agar menonjol
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan masuk untuk mengelola\nKasir Bakso Idola', // Penambahan nama aplikasi
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.4, // Spasi antar baris agar nyaman dibaca
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends ConsumerWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: 'Masuk dengan Google', // Diterjemahkan ke bahasa Indonesia
      onTap: () async {
        var res = await AppDialog.showProgress(() async {
          return ref.read(authControllerProvider).signIn();
        });

        if (res.isSuccess) {
          ref.read(appRoutesProvider).router.refresh();
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Developed by FlyHigh Sinergi',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.outline, // Warna abu-abu pudar
      ),
    );
  }
}