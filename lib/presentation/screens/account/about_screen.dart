import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/assets/assets.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/external_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appName = '';
  String packageName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        titleSpacing: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppImage(
                image: Assets
                    .appLogo,
                imgProvider: ImgProvider.assetImage,
                width: 150,
              ),
              const SizedBox(height: AppSizes.padding),
              Text(
                'Kasir Bakso Idola',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                packageName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                'Versi $version', // Diubah ke Bahasa Indonesia
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSizes.padding),
              Text(
                'Aplikasi Point of Sale (Kasir) modern yang dirancang khusus untuk kemudahan dan kecepatan transaksi.', // Diubah & Disesuaikan
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.padding * 1),
              Text(
                "Aplikasi ini mengutamakan fitur offline-first, di mana seluruh data disimpan secara lokal sehingga transaksi tetap bisa berjalan lancar meskipun tidak ada sinyal internet.\n\nSistem akan secara otomatis menyinkronkan data dengan database pusat (cloud) ketika perangkat kembali terhubung ke internet, memastikan data keuangan Anda selalu aman dan terbarui.", // Diubah & Disesuaikan
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.padding * 2),

              // Bagian Developer Info (Disesuaikan letaknya menjadi ke tengah agar selaras)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Dikembangkan oleh",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "FlyHigh Sinergi", // Nama perusahaan Bapak
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .primary, // Memberikan warna primary agar menonjol
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.padding),

              // Tombol Link Website
              GestureDetector(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Kunjungi Website Kami", // Diubah ke Bahasa Indonesia
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                onTap: () {
                  ExternalLauncher.openUrl('https://flyhighsinergi.com/');
                },
              ),

              const SizedBox(height: AppSizes.padding / 4),

              GestureDetector(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hubungi Bantuan",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.support_agent_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                onTap: () {
                  String text =
                      'Halo, saya butuh bantuan terkait aplikasi Kasir Bakso Idola!';
                  String phone = '6285141168042';
                  String encodedText = Uri.encodeComponent(text);
                  ExternalLauncher.openUrl(
                    'https://api.whatsapp.com/send/?phone=$phone&text=$encodedText&type=phone_number&app_absent=0',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
