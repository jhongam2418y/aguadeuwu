import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/ticket_model.dart';

/// Construye un `pw.Document` para un ticket usando los valores pasados.
/// El objetivo es tener una única implementación compartida para impresión
/// y reimpresión que garantice resultados idénticos.
Future<pw.Document> buildTicketPdfFromValues({
  required int adultos,
  required int ninos,
  required double precioAdulto,
  required double precioNino,
  required double total,
  required String fecha,
  required String hora,
  required String metodoPago,
  required String nroTicket,
  PdfPageFormat? pageFormat,
}) async {
  final pdf = pw.Document();
  const mmPt = PdfPageFormat.mm;

  final partesPago = metodoPago.split('+');

  final logoData = await rootBundle.load('assets/images/marcaDeAgua.png');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

  // Usar márgenes mínimos para que el logo pueda ocupar más espacio horizontal.
  final pageFmt = pageFormat ?? PdfPageFormat(
    80 * mmPt,
    double.infinity,
    marginLeft: 0 * mmPt,
    marginRight: 0 * mmPt,
    marginTop: 0 * mmPt,
    marginBottom: 2 * mmPt,
  );

  pw.Widget pdfRow(String label, String value,
      {bool bold = false, double fontSize = 10}) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)
        : pw.TextStyle(fontSize: fontSize);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: style),
          ),
        ),
      ],
    );
  }

  pdf.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(pageFormat: pageFmt),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.LayoutBuilder(builder: (ctx, constraints) {
            final maxW = constraints?.maxWidth ?? 200.0;
            // Reducir un poco el logo respecto al ancho total y añadir
            // un padding vertical para separar del resto del contenido.
            final logoW = maxW * 0.85;
            return pw.Padding(
              // Reducir padding vertical para empatar con preview
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(child: pw.Image(logoImage, width: logoW)),
            );
          }),
          // Espacio estre (pequeño) entre el logo y la primera fila (NRO. TICKET)
          pw.SizedBox(height: 12),

          pdfRow('NRO. TICKET:', nroTicket),
          pw.SizedBox(height: 1),
          pdfRow('FECHA:', fecha),
          pw.SizedBox(height: 1),
          pdfRow('HORA:', hora),
          pw.SizedBox(height: 1),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 1),

          pdfRow('Adultos S/${precioAdulto.toStringAsFixed(2)} (x$adultos)',
              'S/ ${(adultos * precioAdulto).toStringAsFixed(2)}'),
          if (ninos > 0)
            pdfRow('Niños S/${precioNino.toStringAsFixed(2)} (x$ninos)',
                'S/ ${(ninos * precioNino).toStringAsFixed(2)}'),

          pw.Divider(thickness: 0.5, height: 1),
          pw.SizedBox(height: 1),

          pdfRow('TOTAL:', 'S/ ${total.toStringAsFixed(2)}',
              bold: true, fontSize: 15),
          pw.SizedBox(height: 1),
          pdfRow('Pago:', TicketModel.formatearParte(partesPago[0])),
          if (partesPago.length > 1) ...[
            pw.SizedBox(height: 1),
            pdfRow('', TicketModel.formatearParte(partesPago[1])),
          ],

          pw.SizedBox(height: 2),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 2),
          pw.Text('Gracias por su visita!', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ),
  );

  return pdf;
}
