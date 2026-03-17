import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../../domain/entities/transaction_entity.dart';

class PdfReportService {
  static Future<void> generateAndOpenPdf({
    required List<TransactionEntity> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required String label,
  }) async {
    final pdf = pw.Document();

    // Hitung total pendapatan dari data yang difilter
    final totalRevenue = transactions.fold(0, (sum, item) => sum + item.totalAmount);

    // Membuat halaman PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            //Header
            pw.Text(
              'Laporan Pendapatan - Kasir Bakso Idola',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Periode: $label (${DateTimeFormatter.normal(startDate.toString())} s/d ${DateTimeFormatter.normal(endDate.toString())})',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            // transaksi
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Transaksi: ${transactions.length} Pesanan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total Pendapatan: ${CurrencyFormatter.format(totalRevenue)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              headers: ['ID Transaksi', 'Tanggal', 'Metode', 'Kasir', 'Total'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
              data: transactions.map((t) {
                return [
                  t.id.toString(),
                  DateTimeFormatter.normalWithClock(t.createdAt ?? ''),
                  t.paymentMethod.toUpperCase(),
                  t.cashierName ?? 'Admin',
                  CurrencyFormatter.format(t.totalAmount),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // 4. Proses Menyimpan ke Penyimpanan HP Lokal
    try {
      // Mendapatkan folder dokumen di HP (berlaku untuk Android & iOS)
      final outputDir = await getApplicationDocumentsDirectory();
      
      // Membuat nama file yang unik berdasarkan waktu cetak
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'Laporan_Bakso_Idola_$timestamp.pdf';
      final String fullPath = '${outputDir.path}/$fileName';

      final file = File(fullPath);
      await file.writeAsBytes(await pdf.save());

      // 5. Membuka file PDF secara otomatis menggunakan aplikasi pembaca PDF bawaan HP
      await OpenFilex.open(fullPath);
      
    } catch (e) {
      throw Exception('Gagal menyimpan atau membuka PDF: $e');
    }
  }
}