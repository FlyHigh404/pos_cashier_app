import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';

import '../../../core/assets/assets.dart';
import '../../../core/themes/app_sizes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _body()),
    );
  }

  Widget _body() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppImage(
            image: Assets.welcome,
            imgProvider: ImgProvider.assetImage,
            width: 180,
          ),
          const SizedBox(height: AppSizes.padding * 1.5),
          
          Text(
            'Halo!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Selamat datang di Aplikasi\nKasir Bakso Idola',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: AppSizes.padding * 2.5),
          
          Text(
            'Developed by FlyHigh Sinergi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}