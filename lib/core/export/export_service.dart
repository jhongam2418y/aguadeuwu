import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/tickets/data/models/ticket_model.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ─── CSV ──────────────────────────────────────────────────────────────────
  Future<void> exportarCSV({
    required List<TicketModel> tickets,
    required DateTime desde,
    required DateTime hasta,
    required BuildContext context,
  }) async {
    final rows = <List<dynamic>>[
      ['ID Ticket', 'Fecha', 'Hora', 'Adultos', 'Niños', 'Total (S/)', 'Método Pago', 'Estado'],
      ...tickets.map((t) => [
            '#TK-${t.ticketId}',
            DateFormat('dd/MM/yyyy').format(t.hora),
            DateFormat('HH:mm').format(t.hora),
            t.adultos,
            t.ninos,
            t.monto.toStringAsFixed(2),
            t.metodoPago.split('+').map(TicketModel.formatearParte).join(' + '),
            t.anulado ? 'Anulado' : 'Completado',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await _guardarArchivo(
      contenido: csv,
      nombreSugerido: _nombreArchivo('ventas', desde, hasta, 'csv'),
      extension: 'csv',
      context: context,
    );
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────
  Future<void> exportarPDF({
    required List<TicketModel> tickets,
    required DateTime desde,
    required DateTime hasta,
    required BuildContext context,
  }) async {
    final activos = tickets.where((t) => !t.anulado).toList();
    final totalIngresos = activos.fold<double>(0, (s, t) => s + t.monto);
    final totalPax = activos.fold<int>(0, (s, t) => s + t.adultos + t.ninos);

    final pdf = pw.Document();
    const mmPt = PdfPageFormat.mm;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24 * mmPt),
        build: (ctx) => [
          // Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('PISCIGRANJA',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('Reporte de Ventas',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(
                    'Período: ${DateFormat('dd/MM/yy').format(desde)} — ${DateFormat('dd/MM/yy').format(hasta)}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text(
                    'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              ]),
            ],
          ),
          pw.SizedBox(height: 6 * mmPt),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 4 * mmPt),

          // Tarjetas resumen
          pw.Row(children: [
            _pdfSummaryBox('Tickets activos', '${activos.length}'),
            pw.SizedBox(width: 4 * mmPt),
            _pdfSummaryBox('Total personas', '$totalPax'),
            pw.SizedBox(width: 4 * mmPt),
            _pdfSummaryBox('Ingresos totales', 'S/ ${totalIngresos.toStringAsFixed(2)}'),
            pw.SizedBox(width: 4 * mmPt),
            _pdfSummaryBox('Anulados', '${tickets.length - activos.length}'),
          ]),
          pw.SizedBox(height: 6 * mmPt),

          // Tabla
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              // Cabecera
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0052CC)),
                children: ['ID', 'Fecha / Hora', 'Detalle', 'Pago', 'Monto', 'Estado']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9)),
                        ))
                    .toList(),
              ),
              // Filas
              ...tickets.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final bg = t.anulado
                    ? const PdfColor.fromInt(0xFFFFF0F0)
                    : (i.isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFF));
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    '#TK-${t.ticketId}',
                    '${DateFormat('dd/MM/yy').format(t.hora)}\n${DateFormat('HH:mm').format(t.hora)}',
                    '${t.adultos > 0 ? "${t.adultos} Adulto${t.adultos > 1 ? 's' : ''}" : ""}${t.adultos > 0 && t.ninos > 0 ? " + " : ""}${t.ninos > 0 ? "${t.ninos} Niño${t.ninos > 1 ? 's' : ''}" : ""}',
                    t.metodoPago.split('+').map(TicketModel.formatearParte).join(' + '),
                    'S/ ${t.monto.toStringAsFixed(2)}',
                    t.anulado ? 'Anulado' : 'OK',
                  ]
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: pw.Text(cell,
                                style: pw.TextStyle(
                                    fontSize: 8.5,
                                    color: t.anulado ? PdfColors.red400 : PdfColors.black)),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 4 * mmPt),
          pw.Text('Total de registros: ${tickets.length}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (!context.mounted) return;
    await _guardarArchivo(
      contenido: null,
      bytes: bytes,
      nombreSugerido: _nombreArchivo('reporte', desde, hasta, 'pdf'),
      extension: 'pdf',
      context: context,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  pw.Widget _pdfSummaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFE3F0FF),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0052CC))),
        ]),
      ),
    );
  }

  String _nombreArchivo(String prefijo, DateTime desde, DateTime hasta, String ext) {
    final d = DateFormat('ddMMMyy').format(desde);
    final h = DateFormat('ddMMMyy').format(hasta);
    return desde == hasta ? '${prefijo}_$d.$ext' : '${prefijo}_${d}_al_$h.$ext';
  }

  Future<void> _guardarArchivo({
    String? contenido,
    List<int>? bytes,
    required String nombreSugerido,
    required String extension,
    required BuildContext context,
  }) async {
    // En Windows/Linux/macOS: diálogo de guardar
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo',
        fileName: nombreSugerido,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (path == null) return;
      final file = File(path);
      if (contenido != null) {
        await file.writeAsString(contenido);
      } else {
        await file.writeAsBytes(bytes!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo guardado: $nombreSugerido'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Android/iOS: carpeta de documentos
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir == null) return;
      final path = p.join(dir, nombreSugerido);
      final file = File(path);
      if (contenido != null) {
        await file.writeAsString(contenido);
      } else {
        await file.writeAsBytes(bytes!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Guardado en: $path'),
          action: !Platform.isWindows
              ? SnackBarAction(
                  label: 'Abrir', onPressed: () => OpenFilex.open(path))
              : null,
        ));
      }
    }
  }
}