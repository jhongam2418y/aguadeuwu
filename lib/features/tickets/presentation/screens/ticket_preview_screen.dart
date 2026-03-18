import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../providers/ticket_provider.dart';

class TicketPreviewScreen extends StatefulWidget {
  final int adultos, ninos;
  final double precioAdulto, precioNino, total;
  final String metodoPago;
  final VoidCallback onSalir;
  final Future<int> Function() onGuardar;

  const TicketPreviewScreen({
    super.key,
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodoPago,
    required this.onSalir,
    required this.onGuardar,
  });

  @override
  State<TicketPreviewScreen> createState() => _TicketPreviewScreenState();
}

class _TicketPreviewScreenState extends State<TicketPreviewScreen> {
  bool _guardado = false;
  int? _ticketDbId;

  int get adultos => widget.adultos;
  int get ninos => widget.ninos;
  double get precioAdulto => widget.precioAdulto;
  double get precioNino => widget.precioNino;
  double get total => widget.total;
  String get metodoPago => widget.metodoPago;

  String get _fecha {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  String get _hora {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<pw.Document> _buildPdf() async {
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
              pw.Text('PISCIGRANJA',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Boletería', style: const pw.TextStyle(fontSize: 10)),
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
              pw.SizedBox(height: 4),
              pw.Text('Pago: ${metodoPago[0].toUpperCase()}${metodoPago.substring(1)}',
                  style: const pw.TextStyle(fontSize: 10)),
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
    return pdf;
  }

  Future<void> _confirmarAnulacion(BuildContext context) async {
    if (!_guardado) {
      widget.onSalir();
      Navigator.pop(context);
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Ticket'),
        content: const Text(
            'Este ticket ya fue guardado. ¿Desea anularlo? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirmar == true && _ticketDbId != null && mounted) {
      await context.read<TicketProvider>().anularTicket(_ticketDbId!);
      if (!context.mounted) return; 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ticket anulado correctamente'),
          backgroundColor: Colors.red,
        ));
        widget.onSalir();
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  Future<void> _imprimir(BuildContext context) async {
    if (!_guardado) {
      _ticketDbId = await widget.onGuardar();
      setState(() => _guardado = true);
    }
    final pdf = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ConfigProvider>();
    final impresora =
        cfg.nombreImpresora.isEmpty ? 'No configurada' : cfg.nombreImpresora;
    final conectado = cfg.nombreImpresora.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0052CC), Color(0xFF003D99)]),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: const Column(
                children: [
                  Text('PISCIGRANJA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  SizedBox(height: 2),
                  Text('Vista Previa del Ticket',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),


            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Expanded(
                    flex: 60,
                    child: Container(
                      color: const Color(0xFFDDE6F0),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 28),
                          child: SizedBox(
                            width: 340,
                            child: _TicketCard(
                              adultos: adultos,
                              ninos: ninos,
                              precioAdulto: precioAdulto,
                              precioNino: precioNino,
                              total: total,
                              fecha: _fecha,
                              hora: _hora,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),


                  Expanded(
                    flex: 40,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card de acciones
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.07),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Título
                                Row(children: const [
                                  Icon(Icons.print_rounded,
                                      color: Color(0xFF0052CC), size: 22),
                                  SizedBox(width: 8),
                                  Text('Acciones del Ticket',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A1A))),
                                ]),
                                const SizedBox(height: 20),
                                // Imprimir Ticket
                                ElevatedButton.icon(
                                  onPressed: () => _imprimir(context),
                                  icon: const Icon(Icons.print_rounded,
                                      size: 24),
                                  label: const Text('Imprimir Ticket',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF0052CC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 22),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 3,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Editar Datos
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 22),
                                  label: const Text('Editar Datos',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF0052CC),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    side: const BorderSide(
                                        color: Color(0xFF90CAF9),
                                        width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Anular / Cancelar
                                OutlinedButton.icon(
                                  onPressed: () => _confirmarAnulacion(context),
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.red.shade600, size: 22),
                                  label: Text(
                                      _guardado ? 'Anular Ticket' : 'Cancelar',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    side: BorderSide(
                                        color: Colors.red.shade200,
                                        width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Volver al Panel Principal
                          _DashedButton(
                            onTap: () {
                              widget.onSalir();
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            },
                          ),

                          const Spacer(),

                          // Impresora info card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: conectado
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF8E1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    conectado
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_amber_rounded,
                                    color: conectado
                                        ? Colors.green.shade600
                                        : Colors.orange,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('IMPRESORA',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2)),
                                    const SizedBox(height: 4),
                                    Text(impresora,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1A1A))),
                                    Text(
                                      conectado
                                          ? 'Conectado y listo'
                                          : 'No configurada',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: conectado
                                              ? Colors.green.shade600
                                              : Colors.orange),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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



class _TicketCard extends StatelessWidget {
  final int adultos, ninos;
  final double precioAdulto, precioNino, total;
  final String fecha, hora;

  const _TicketCard({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.fecha,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Franja azul
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0052CC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                // Encabezado
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    children: [
                      Text('PISCIGRANJA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 2.5)),
                      SizedBox(height: 2),
                      Text('Boletería de Ingreso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const _TicketDivider(),
                // FECHA / HORA / TIPO
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      _TicketRow(label: 'FECHA:', value: fecha),
                      const SizedBox(height: 7),
                      _TicketRow(label: 'HORA:', value: hora),
                      const SizedBox(height: 7),
                      _TicketRow(
                          label: 'TIPO:', value: 'ENTRADA GENERAL'),
                    ],
                  ),
                ),
                const _TicketDivider(),
                // Items
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      if (adultos > 0)
                        _TicketRow(
                          label: 'Adultos (x$adultos)',
                          value:
                              'S/ ${(adultos * precioAdulto).toStringAsFixed(2)}',
                        ),
                      if (adultos > 0 && ninos > 0)
                        const SizedBox(height: 7),
                      if (ninos > 0)
                        _TicketRow(
                          label: 'Niños (x$ninos)',
                          value:
                              'S/ ${(ninos * precioNino).toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                ),
                const _TicketDivider(thick: true),
                // TOTAL
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL ESTIMADO:',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14)),
                      Text('S/ ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                ),
                const _TicketDivider(),
                // Gracias
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text('¡GRACIAS POR SU VISITA!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5)),
                ),
                // Código de barras visual
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(180, 42),
                      painter: _BarcodePainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ClipRect(
            child: SizedBox(
              height: 14,
              child: Row(
                children: List.generate(
                  31,
                  (i) => Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFDDE6F0),
                        borderRadius: i.isEven
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(7))
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketDivider extends StatelessWidget {
  final bool thick;
  const _TicketDivider({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Divider(
        thickness: thick ? 1.5 : 0.8,
        indent: 16,
        endIndent: 16,
        color: Colors.grey.shade300);
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade700;
    final rng = [3, 1, 2, 4, 1, 3, 2, 1, 4, 2, 1, 3, 2, 1, 2, 4,
                 1, 3, 2, 1, 3, 2, 4, 1, 2, 3, 1, 2, 1, 3, 2, 1];
    double x = 0;
    bool draw = true;
    for (final w in rng) {
      final barW = w * (size.width / 56);
      if (draw) canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      x += barW;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => false;
}



class _DashedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DashedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF0052CC)),
              SizedBox(width: 8),
              Text('Volver al Panel Principal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0052CC))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 6.0;
    const gapW = 4.0;
    final paint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    final metricsList = path.computeMetrics();
    for (final metric in metricsList) {
      double dist = 0;
      bool drawing = true;
      while (dist < metric.length) {
        final len = drawing ? dashW : gapW;
        final end = (dist + len).clamp(0.0, metric.length);
        if (drawing) {
          canvas.drawPath(metric.extractPath(dist, end), paint);
        }
        dist += len;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}



class _TicketRow extends StatelessWidget {
  final String label, value;
  const _TicketRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const size = 13.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
