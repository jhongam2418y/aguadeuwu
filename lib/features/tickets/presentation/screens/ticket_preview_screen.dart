import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketPreviewScreen extends StatelessWidget {
  final int adultos, ninos;
  final double precioAdulto, precioNino, total, montoEntregado, vuelto;
  final String metodoPago;
  final VoidCallback onSalir;

  const TicketPreviewScreen({
    super.key,
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodoPago,
    required this.montoEntregado,
    required this.vuelto,
    required this.onSalir,
  });

  String get _fecha {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  String get _hora {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _imprimir(BuildContext context) async {
    final pdf = pw.Document();
    const mmPt = PdfPageFormat.mm;

    pw.Widget pdfRow(String label, String value,
        {bool bold = false, double fontSize = 11}) {
      final style = bold
          ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)
          : pw.TextStyle(fontSize: fontSize);
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(80 * mmPt, double.infinity, marginAll: 8 * mmPt),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('TICKET EXPRESS',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Est. 2024', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pdfRow('TIPO:', 'Nueva Entrada'),
              pw.SizedBox(height: 3),
              pdfRow('FECHA:', _fecha),
              pw.SizedBox(height: 3),
              pdfRow('HORA:', _hora),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              if (adultos > 0) ...[
                pdfRow('Adultos (x$adultos)',
                    'S/ ${(adultos * precioAdulto).toStringAsFixed(2)}'),
                pw.SizedBox(height: 3),
              ],
              if (ninos > 0) ...[
                pdfRow('Niños  (x$ninos)',
                    'S/ ${(ninos * precioNino).toStringAsFixed(2)}'),
                pw.SizedBox(height: 3),
              ],
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pdfRow('Subtotal:', 'S/ ${total.toStringAsFixed(2)}'),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 4),
              pdfRow('TOTAL:', 'S/ ${total.toStringAsFixed(2)}',
                  bold: true, fontSize: 16),
              if (metodoPago == 'efectivo') ...[
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                pdfRow('Efectivo:',
                    'S/ ${montoEntregado.toStringAsFixed(2)}'),
                pw.SizedBox(height: 3),
                pdfRow('Vuelto:', 'S/ ${vuelto.toStringAsFixed(2)}'),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Text('¡Gracias por su compra!',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Column(
                    children: [
                      Text('PISCIGRANJA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      SizedBox(height: 2),
                      Text('Vista Previa del Ticket',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: TextButton.icon(
                      onPressed: () {
                        onSalir();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 18),
                      label: const Text('Salir',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      style:
                          TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: Container(
                    width: 330,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.13),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 22, 20, 6),
                          child: Column(
                            children: const [
                              Text('TICKET EXPRESS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: 1)),
                              SizedBox(height: 2),
                              Text('Est. 2024',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Column(
                            children: [
                              _TicketRow(label: 'TIPO:', value: 'Nueva Entrada'),
                              const SizedBox(height: 6),
                              _TicketRow(label: 'FECHA:', value: _fecha),
                              const SizedBox(height: 6),
                              _TicketRow(label: 'HORA:', value: _hora),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Column(
                            children: [
                              if (adultos > 0)
                                _TicketRow(
                                  label: 'Adultos (x$adultos)',
                                  value:
                                      'S/ ${(adultos * precioAdulto).toStringAsFixed(2)}',
                                ),
                              if (adultos > 0 && ninos > 0)
                                const SizedBox(height: 6),
                              if (ninos > 0)
                                _TicketRow(
                                  label: 'Niños (x$ninos)',
                                  value:
                                      'S/ ${(ninos * precioNino).toStringAsFixed(2)}',
                                ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: _TicketRow(
                            label: 'Subtotal:',
                            value: 'S/ ${total.toStringAsFixed(2)}',
                          ),
                        ),
                        const Divider(thickness: 2, indent: 16, endIndent: 16),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 14),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20)),
                              Text('S/ ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20)),
                            ],
                          ),
                        ),
                        if (metodoPago == 'efectivo') ...[
                          const Divider(
                              thickness: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Column(
                              children: [
                                _TicketRow(
                                    label: 'Efectivo:',
                                    value:
                                        'S/ ${montoEntregado.toStringAsFixed(2)}'),
                                const SizedBox(height: 6),
                                _TicketRow(
                                    label: 'Vuelto:',
                                    value:
                                        'S/ ${vuelto.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                        const Divider(thickness: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          child: Text('¡Gracias por su compra!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text('EDITAR',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(
                            color: Color(0xFF1565C0), width: 2),
                        foregroundColor: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _imprimir(context),
                      icon: const Icon(Icons.print_rounded, size: 22),
                      label: const Text('IMPRIMIR',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label, value;
  const _TicketRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
