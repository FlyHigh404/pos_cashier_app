import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../domain/entities/transaction_entity.dart';
import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';
import '../../utilities/currency_formatter.dart';
import '../../utilities/date_time_formatter.dart';

class PrinterService {
  final PrinterManager _manager = PrinterManager();
  final SharedPreferences _sharedPreferences;

  PrinterService(this._sharedPreferences);

  List<PrinterDevice> printers = [];
  PrinterDevice? selectedPrinter;

  PrinterConnectionState get connectionState => _manager.state;
  Stream<PrinterConnectionState> get stateStream => _manager.stateStream;
  bool get isConnected => _manager.isConnected;

  PaperSize get paperSize {
    final saved = _sharedPreferences.getString(Constants.selectedPaperSizeKey);
    return switch (saved) {
      'mm72' => PaperSize.mm72,
      'mm80' => PaperSize.mm80,
      _ => PaperSize.mm58,
    };
  }

  void setPaperSize(PaperSize size) {
    final key = switch (size) {
      PaperSize.mm58 => 'mm58',
      PaperSize.mm72 => 'mm72',
      PaperSize.mm80 => 'mm80',
    };
    _sharedPreferences.setString(Constants.selectedPaperSizeKey, key);
  }

  Future<Result<void>> scanPrinters({
    Set<PrinterConnectionType> types = const {
      PrinterConnectionType.usb,
      PrinterConnectionType.bluetooth,
      PrinterConnectionType.ble,
      PrinterConnectionType.network,
    },
    String? selectedDeviceId,
    Function(List<PrinterDevice>)? onDeviceStream,
  }) async {
    final permissions = await checkPermissions();
    if (permissions.isFailure) return Result.failure(error: permissions.error!);

    try {
      printers = [];
      final stream = _manager.scanAll(
        timeout: const Duration(seconds: 5),
        types: types,
      );

      await for (final devices in stream) {
        for (final device in devices) {
          if (!printers.any((p) => getDeviceId(p) == getDeviceId(device))) {
            printers.add(device);
          }
        }

        onDeviceStream?.call(printers);

        if (selectedDeviceId != null && !(_manager.state == PrinterConnectionState.scanning)) {
          final match = printers.where((d) => getDeviceId(d) == selectedDeviceId).firstOrNull;
          if (match != null && selectedPrinter == null) {
            final result = await selectPrinter(match);
            if (result.isFailure) {
              return Result.failure(error: result.error!);
            }
          } else if (match != null) {
            // Update reference to the new scan instance without reconnecting
            selectedPrinter = match;
          }
        }
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> selectPrinter(PrinterDevice device) async {
    cl('[PrinterService].selectPrinter: ${device.name} (${device.connectionType.name})');

    try {
      final currentSelectedDeviceId = selectedPrinter == null ? null : getDeviceId(selectedPrinter!);
      final nextSelectedDeviceId = getDeviceId(device);

      if (_manager.isConnected && currentSelectedDeviceId == nextSelectedDeviceId) {
        selectedPrinter = device;
        return Result.success(data: null);
      }

      if (_manager.isConnected) {
        await _manager.disconnect();
      }

      await _manager.connect(device, timeout: const Duration(seconds: 10));
      selectedPrinter = device;
      return Result.success(data: null);
    } on PrinterException catch (e) {
      if (!_manager.isConnected) {
        selectedPrinter = null;
      }

      cl('[PrinterService].selectPrinter connection error: ${e.message}');
      return Result.failure(error: e.message);
    } catch (e) {
      if (!_manager.isConnected) {
        selectedPrinter = null;
      }

      cl('[PrinterService].selectPrinter connection error: $e');
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> disconnectPrinter() async {
    try {
      if (_manager.isConnected) {
        await _manager.disconnect();
      }

      selectedPrinter = null;
      return Result.success(data: null);
    } on PrinterException catch (e) {
      cl('[PrinterService].disconnectPrinter error: ${e.message}');
      return Result.failure(error: e.message);
    } catch (e) {
      cl('[PrinterService].disconnectPrinter error: $e');
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printTicket(Ticket ticket) async {
    if (selectedPrinter == null) {
      return Result.failure(error: 'Printer is not selected yet!');
    }

    try {
      if (!_manager.isConnected) {
        await _manager.connect(selectedPrinter!, timeout: const Duration(seconds: 10));
      }

      await _manager.printTicket(ticket);
      return Result.success(data: null);
    } on PrinterException catch (e) {
      return Result.failure(error: e.message);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printData(List<int> bytes) async {
    if (selectedPrinter == null) {
      return Result.failure(error: 'Printer is not selected yet!');
    }

    try {
      if (!_manager.isConnected) {
        await _manager.connect(selectedPrinter!, timeout: const Duration(seconds: 10));
      }

      await _manager.printBytes(bytes);
      return Result.success(data: null);
    } on PrinterException catch (e) {
      return Result.failure(error: e.message);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printTransaction(TransactionEntity transaction) async {
    try {
      final ticket = await Ticket.create(paperSize);

      // --- HEADER ---
      ticket.text(
        'BAKSO IDOLA',
        align: PrintAlign.center,
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
          width: TextSize.size2,
        ),
      );
      ticket.text(
        'by "DD"',
        align: PrintAlign.center,
      );
      ticket.text(
        '100% Bakso Ayam',
        align: PrintAlign.center,
      );
      ticket.text(
        'Jl. Laksamana-Baktisegara,\nDesa Bangkang',
        align: PrintAlign.center,
        style: const PrintTextStyle(
          height: TextSize.size1,
          width: TextSize.size1,
        ),
      );

      ticket.emptyLines();

      // --- INFO TRANSAKSI ---
      // final date = DateTimeFormatter.slashDateShortedYearWithClock(
      //   transaction.createdAt ?? DateTime.now().toIso8601String(),
      // );
      final dateTime = DateTime.parse(transaction.createdAt ?? DateTime.now().toIso8601String()).toLocal();
      final date = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
      final time = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

      ticket.row([
        PrintColumn(text: 'No Invoice', flex: 4),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(text: '${transaction.id}', flex: 7),
      ]);
      ticket.row([
        PrintColumn(text: 'Tanggal', flex: 4),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(text: date, flex: 7),
      ]);
      ticket.row([
        PrintColumn(text: 'Waktu', flex: 4),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(text: time, flex: 7),
      ]);

      ticket.separator();

      // --- HEADER MENU ---
      ticket.row([
        PrintColumn(
          text: 'Menu',
          flex: 2,
          style: const PrintTextStyle(bold: true),
        ),
        PrintColumn(
          text: 'Subtotal',
          flex: 2,
          align: PrintAlign.right,
          style: const PrintTextStyle(bold: true),
        ),
      ]);
      
      ticket.separator();

      // --- DAFTAR ITEM ---
      if (transaction.orderedProducts != null) {
        for (final product in transaction.orderedProducts!) {
          // Baris 1: Nama Produk
          ticket.text(product.name);
          
          // Baris 2: Jumlah & Total Bayar
          ticket.row([
            PrintColumn(
              text: '  ${product.quantity}x @ ${CurrencyFormatter.format(product.price)}',
              flex: 2,
            ),
            PrintColumn(
              text: CurrencyFormatter.format(product.price * product.quantity),
              flex: 2,
              align: PrintAlign.right,
            ),
          ]);
        }
      }

      ticket.separator();

      // --- TOTAL & PEMBAYARAN ---
      ticket.row([
        PrintColumn(text: 'Total', flex: 10, style: const PrintTextStyle(bold: true)),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(
          text: CurrencyFormatter.format(transaction.totalAmount),
          flex: 6,
          align: PrintAlign.right,
          style: const PrintTextStyle(bold: true),
        ),
      ]);
      ticket.row([
        PrintColumn(text: 'Metode Pembayaran', flex: 10),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(
          text: (transaction.paymentMethod ?? '').toUpperCase(),
          flex: 6,
          align: PrintAlign.right,
        ),
      ]);
      ticket.row([
        PrintColumn(text: 'Jumlah Bayar', flex: 10),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(
          text: CurrencyFormatter.format(transaction.receivedAmount),
          flex: 6,
          align: PrintAlign.right,
        ),
      ]);
      ticket.row([
        PrintColumn(text: 'Kembali', flex: 10),
        PrintColumn(text: ':', flex: 1, align: PrintAlign.center),
        PrintColumn(
          text: CurrencyFormatter.format(transaction.returnAmount),
          flex: 6,
          align: PrintAlign.right,
        ),
      ]);

      // --- FOOTER ---
      ticket.emptyLines();
      ticket.text('SELAMAT MENIKMATI', align: PrintAlign.center, style: const PrintTextStyle(bold: true));
      ticket.text('MATUR SUKSMA', align: PrintAlign.center);
      ticket.text('Menerima Pesanan', align: PrintAlign.center);
      ticket.text('0881-0372-03222 (Dede)', align: PrintAlign.center);
      
      // Beri jarak untuk disobek (tergantung printernya)
      ticket.cut(linesBefore: 4);

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }
  Future<Result<void>> testPrint() async {
    try {
      final ticket = await Ticket.create(paperSize);

      ticket.row([
        PrintColumn(
          text: 'top left',
          flex: 1,
        ),
        PrintColumn(
          text: 'top right',
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);

      ticket.emptyLines(3);

      ticket.text(
        'FLUTTER POS PRINT TEST OK',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      await ticket.textRaster(
        'ありがとうございます',
        align: PrintAlign.center,
      );

      ticket.emptyLines(3);

      ticket.row([
        PrintColumn(
          text: 'bottom left',
          flex: 1,
        ),
        PrintColumn(
          text: 'bottom right',
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);

      ticket.feed(4);
      ticket.cut();

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> checkPermissions() async {
    final isBluetoothScanGranted = await Permission.bluetoothScan.request();
    if (isBluetoothScanGranted.isDenied) {
      return Result.failure(error: 'Bluetooth scan permission is not granted!');
    }

    final isBluetoothConnectGranted = await Permission.bluetoothConnect.request();
    if (isBluetoothConnectGranted.isDenied) {
      return Result.failure(error: 'Bluetooth connect permission is not granted!');
    }

    return Result.success(data: null);
  }

  String getDeviceId(PrinterDevice device) {
    return switch (device) {
      NetworkPrinterDevice d => '${d.host}:${d.port}',
      BlePrinterDevice d => d.deviceId,
      BluetoothPrinterDevice d => d.address,
      UsbPrinterDevice d => d.identifier,
      _ => device.name,
    };
  }

  Future<void> dispose() async {
    await _manager.dispose();
  }
}
