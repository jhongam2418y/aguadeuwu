import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../configuracion/presentation/providers/config_provider.dart';
import '../providers/ticket_provider.dart';

// ─── Constantes de diseño ────────────────────────────────────────────────────
abstract final class _C {
  static const primary     = Color(0xFF00695C);
  static const primaryDark = Color(0xFF004D40);
  static const blueBorder  = Color(0xFF80CBC4);
  static const text        = Color(0xFF1A1A1A);
  static const background  = Color(0xFFF1FAF8);
  static const panelBg     = Color(0xFFD0EEEA);
}

// Formateadores — instanciados una sola vez
final _fmtFecha = DateFormat('dd/MM/yyyy');
final _fmtHora  = DateFormat('HH:mm');

// =============================================================================
// TicketPreviewScreen
// =============================================================================
class TicketPreviewScreen extends StatefulWidget {
  final int adultos;
  final int ninos;
  final double precioAdulto;
  final double precioNino;
  final double total;
  final String metodoPago;
  final VoidCallback onSalir;
  final Future<int?> Function() onGuardar;

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
  bool _guardado   = false;
  int? _ticketDbId;
  bool _isLoading  = false;

  // Snapshot de fecha/hora al momento de abrir la pantalla — no cambia
  late final DateTime _ahora = DateTime.now();
  late final String _fecha   = _fmtFecha.format(_ahora);
  late final String _hora    = _fmtHora.format(_ahora);

  // Accesos cortos a widget (evita widget.x repetido)
  int    get _adultos      => widget.adultos;
  int    get _ninos        => widget.ninos;
  double get _precioAdulto => widget.precioAdulto;
  double get _precioNino   => widget.precioNino;
  double get _total        => widget.total;
  String get _metodoPago   => widget.metodoPago;

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  void _setLoading(bool v) => setState(() => _isLoading = v);

  void _showSnack(String msg, {Color bg = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  Future<pw.Document> _buildPdf() async {
    final pdf   = pw.Document();
    const mmPt  = PdfPageFormat.mm;
    final pago  = '${_metodoPago[0].toUpperCase()}${_metodoPago.substring(1)}';

    // Helper interno al método — no necesita ser un getter del estado
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
        pageFormat: PdfPageFormat(80 * mmPt, double.infinity, marginAll: 8 * mmPt),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('PISCIGRANJA',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('Boleteria', style: const pw.TextStyle(fontSize: 10)),
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
            if (_adultos > 0) ...[
              pdfRow('Adultos (x$_adultos)',
                  'S/ ${(_adultos * _precioAdulto).toStringAsFixed(2)}'),
              pw.SizedBox(height: 3),
            ],
            if (_ninos > 0) ...[
              pdfRow('Ninos  (x$_ninos)',
                  'S/ ${(_ninos * _precioNino).toStringAsFixed(2)}'),
              pw.SizedBox(height: 3),
            ],
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pdfRow('Subtotal:', 'S/ ${_total.toStringAsFixed(2)}'),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 4),
            pdfRow('TOTAL:', 'S/ ${_total.toStringAsFixed(2)}',
                bold: true, fontSize: 16),
            pw.SizedBox(height: 4),
            pw.Text('Pago: $pago', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Text('Gracias por su compra!',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
    return pdf;
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _imprimir() async {
    _setLoading(true);
    // Leer el nombre antes de cualquier await para evitar uso de context tras gap async
    final nombreImpresora = context.read<ConfigProvider>().nombreImpresora.trim();
    try {
      if (!_guardado) {
        _ticketDbId = await widget.onGuardar();
        if (_ticketDbId == null) throw Exception('No se pudo guardar el ticket.');
        setState(() => _guardado = true);
      }
      final pdf = await _buildPdf();
      final pdfBytes = await pdf.save();

      if (nombreImpresora.isNotEmpty) {
        // Buscar la impresora por nombre y enviar directo
        final impresoras = await Printing.listPrinters();
        final impresora = impresoras.firstWhere(
          (p) => p.name == nombreImpresora,
          orElse: () => throw Exception(
              'Impresora "$nombreImpresora" no encontrada. Verifica el nombre en Configuración.'),
        );
        await Printing.directPrintPdf(
          printer: impresora,
          onLayout: (_) async => pdfBytes,
        );
      } else {
        // Sin impresora configurada: abrir diálogo del sistema
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      }

      _showSnack('Ticket impreso correctamente');
    } catch (e) {
      _showSnack('Error al imprimir: $e', bg: Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _confirmarAnulacion() async {
    // Aún no guardado → simplemente cancelar
    if (!_guardado) {
      widget.onSalir();
      if (mounted) Navigator.pop(context);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Ticket'),
        content: const Text(
          'Este ticket ya fue guardado. ¿Desea anularlo?\n'
          'Esta acción no se puede deshacer.',
        ),
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

    if (!mounted || confirmar != true || _ticketDbId == null) return;

    _setLoading(true);
    try {
      await context.read<TicketProvider>().anularTicket(_ticketDbId!);
      _showSnack('Ticket anulado correctamente', bg: Colors.red);
      if (!mounted) return;
      widget.onSalir();
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _showSnack('Error al anular: $e', bg: Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nombreImpresora = context.select<ConfigProvider, String>(
      (c) => c.nombreImpresora,
    );
    final conectado = nombreImpresora.isNotEmpty;

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const _PreviewHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Panel izquierdo: vista del ticket ─────────────────
                      Expanded(
                        flex: 60,
                        child: ColoredBox(
                          color: _C.panelBg,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 36, vertical: 28),
                              child: SizedBox(
                                width: 340,
                                child: _TicketCard(
                                  adultos:      _adultos,
                                  ninos:        _ninos,
                                  precioAdulto: _precioAdulto,
                                  precioNino:   _precioNino,
                                  total:        _total,
                                  fecha:        _fecha,
                                  hora:         _hora,
                                  metodoPago:   _metodoPago,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Panel derecho: acciones ───────────────────────────
                      Expanded(
                        flex: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 28, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ActionsCard(
                                isLoading:  _isLoading,
                                guardado:   _guardado,
                                onImprimir: _imprimir,
                                onEditar:   () => Navigator.pop(context),
                                onAnular:   _confirmarAnulacion,
                              ),
                              const SizedBox(height: 14),
                              _DashedButton(
                                onTap: _isLoading
                                    ? () {}
                                    : () {
                                        widget.onSalir();
                                        Navigator.of(context)
                                            .popUntil((r) => r.isFirst);
                                      },
                              ),
                              const Spacer(),
                              _PrinterInfo(
                                nombre:    nombreImpresora.isEmpty
                                    ? 'No configurada'
                                    : nombreImpresora,
                                conectado: conectado,
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

            // Overlay de carga
            if (_isLoading)
              const ColoredBox(
                color: Color(0x73000000), // ~45% opacidad
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _PreviewHeader  (const)
// =============================================================================
class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  // Decoración estática — se crea una sola vez
  static const _gradient = BoxDecoration(
    gradient: LinearGradient(colors: [_C.primary, _C.primaryDark]),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _gradient,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: const Column(
        children: [
          Text(
            'PISCIGRANJA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Vista Previa del Ticket',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ActionsCard  — tarjeta con los tres botones de acción
// =============================================================================
class _ActionsCard extends StatelessWidget {
  final bool isLoading;
  final bool guardado;
  final VoidCallback onImprimir;
  final VoidCallback onEditar;
  final VoidCallback onAnular;

  const _ActionsCard({
    required this.isLoading,
    required this.guardado,
    required this.onImprimir,
    required this.onEditar,
    required this.onAnular,
  });

  // Estilos estáticos — se construyen una vez
  static final _printStyle = ElevatedButton.styleFrom(
    backgroundColor: _C.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 30),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
  );

  static final _editStyle = OutlinedButton.styleFrom(
    foregroundColor: _C.primary,
    padding: const EdgeInsets.symmetric(vertical: 26),
    side: const BorderSide(color: _C.blueBorder, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final cancelStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.red.shade600,
      padding: const EdgeInsets.symmetric(vertical: 26),
      side: BorderSide(color: Colors.red.shade200, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          const Row(
            children: [
              Icon(Icons.print_rounded, color: _C.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Acciones del Ticket',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Imprimir
          ElevatedButton.icon(
            onPressed: isLoading ? null : onImprimir,
            icon: const Icon(Icons.print_rounded, size: 26),
            label: const Text(
              'Imprimir Ticket',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            style: _printStyle,
          ),
          const SizedBox(height: 24),

          // Editar
          OutlinedButton.icon(
            onPressed: isLoading ? null : onEditar,
            icon: const Icon(Icons.edit_rounded, size: 24),
            label: const Text(
              'Editar Datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: _editStyle,
          ),
          const SizedBox(height: 16),

          // Anular / Cancelar
          OutlinedButton.icon(
            onPressed: isLoading ? null : onAnular,
            icon: Icon(Icons.close_rounded, color: Colors.red.shade600, size: 24),
            label: Text(
              guardado ? 'Anular Ticket' : 'Cancelar',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: cancelStyle,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _PrinterInfo  — widget separado para info de impresora
// =============================================================================
class _PrinterInfo extends StatelessWidget {
  final String nombre;
  final bool conectado;
  const _PrinterInfo({required this.nombre, required this.conectado});

  @override
  Widget build(BuildContext context) {
    final iconColor  = conectado ? Colors.green.shade600 : Colors.orange;
    final iconBgColor = conectado
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF8E1);
    final statusText = conectado ? 'Conectado y listo' : 'No configurada';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(
              conectado ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IMPRESORA',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, color: iconColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _TicketCard
// =============================================================================
class _TicketCard extends StatelessWidget {
  final int adultos, ninos;
  final double precioAdulto, precioNino, total;
  final String fecha, hora, metodoPago;

  const _TicketCard({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.fecha,
    required this.hora,
    required this.metodoPago,
  });

  // Sombra estática
  static const _shadow = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            boxShadow: [_shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja superior azul
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: _C.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: SizedBox(height: 6),
              ),

              // Encabezado
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  children: [
                    Text(
                      'PISCIGRANJA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Boleteria de Ingreso',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const _TicketDivider(),

              // Fecha / Hora / Tipo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    _TicketRow(label: 'FECHA:', value: fecha),
                    const SizedBox(height: 7),
                    _TicketRow(label: 'HORA:', value: hora),
                    const SizedBox(height: 7),
                    const _TicketRow(label: 'TIPO:', value: 'ENTRADA GENERAL'),
                    const SizedBox(height: 7),
                    _TicketRow(
                      label: 'PAGO:',
                      value: '${metodoPago[0].toUpperCase()}${metodoPago.substring(1)}',
                    ),
                  ],
                ),
              ),
              const _TicketDivider(),

              // Ítems
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    if (adultos > 0)
                      _TicketRow(
                        label: 'Adultos (x$adultos)',
                        value: 'S/ ${(adultos * precioAdulto).toStringAsFixed(2)}',
                      ),
                    if (adultos > 0 && ninos > 0) const SizedBox(height: 7),
                    if (ninos > 0)
                      _TicketRow(
                        label: 'Ninos (x$ninos)',
                        value: 'S/ ${(ninos * precioNino).toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),
              const _TicketDivider(thick: true),

              // Total
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL ESTIMADO:',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      'S/ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const _TicketDivider(),

              // Gracias
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'GRACIAS POR SU VISITA!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Código de barras
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

        // Borde dentado inferior
        _TicketTear(bgColor: _C.panelBg),
      ],
    );
  }
}

// =============================================================================
// _TicketTear  — borde dentado extraído como widget
// =============================================================================
class _TicketTear extends StatelessWidget {
  final Color bgColor;
  const _TicketTear({required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: 14,
        child: Row(
          children: List.generate(
            31,
            (i) => Expanded(
              child: SizedBox(
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i.isEven ? Colors.white : bgColor,
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
    );
  }
}

// =============================================================================
// Widgets auxiliares del ticket
// =============================================================================
class _TicketDivider extends StatelessWidget {
  final bool thick;
  const _TicketDivider({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: thick ? 1.5 : 0.8,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade300,
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// =============================================================================
// _BarcodePainter  — lista de anchos como const
// =============================================================================
class _BarcodePainter extends CustomPainter {
  static const _bars = [
    3, 1, 2, 4, 1, 3, 2, 1, 4, 2, 1, 3, 2, 1, 2, 4,
    1, 3, 2, 1, 3, 2, 4, 1, 2, 3, 1, 2, 1, 3, 2, 1,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade700;
    double x = 0;
    bool draw = true;
    for (final w in _bars) {
      final barW = w * (size.width / 56);
      if (draw) canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      x += barW;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter _) => false;
}

// =============================================================================
// _DashedButton
// =============================================================================
class _DashedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DashedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_rounded, size: 20, color: _C.primary),
              SizedBox(width: 8),
              Text(
                'Volver al Panel Principal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _C.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DashedBorderPainter  (const constructor)
// =============================================================================
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  static const _dashW = 6.0;
  static const _gapW  = 4.0;
  static final _paint = Paint()
    ..color      = _C.blueBorder
    ..strokeWidth = 1.5
    ..style      = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10),
      ));
    for (final metric in path.computeMetrics()) {
      double dist   = 0;
      bool drawing  = true;
      while (dist < metric.length) {
        final len = drawing ? _dashW : _gapW;
        final end = (dist + len).clamp(0.0, metric.length);
        if (drawing) canvas.drawPath(metric.extractPath(dist, end), _paint);
        dist    += len;
        drawing  = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter _) => false;
}