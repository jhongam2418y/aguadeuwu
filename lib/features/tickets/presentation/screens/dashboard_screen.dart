import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/update/update_dialog.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../../../configuracion/presentation/screens/configuracion_screen.dart';
import '../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../widgets/stat_card.dart';
import 'boleteria_screen.dart';

// ─── Aliases a AppColors ──────────────────────────────────────────────────────
abstract final class _AppColors {
  static const primary      = AppColors.primaryBlue;
  static const primaryDark  = AppColors.darkBlue;
  static const primaryLight = AppColors.primaryLight;
  static const green        = AppColors.green;
  static const greenLight   = AppColors.greenLight;
  static const text         = AppColors.text;
  static const textSoft     = AppColors.textSoft;
  static const background   = AppColors.lightBlueBackground;
}

// ─── Formateadores reutilizables ──────────────────────────────────────────────
final _fmtHora  = DateFormat('HH:mm');
final _fmtDia   = DateFormat('EEEE', 'es');
final _fmtFecha = DateFormat("EEEE d 'de' MMMM", 'es');

// =============================================================================
// DashboardScreen
// =============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().cargarTicketsHoy();
      checkAndPromptUpdate(context);
    });
  }

  Future<void> _irABoleteria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BoleteriaScreen()),
    );
    if (mounted) context.read<TicketProvider>().cargarTicketsHoy();
  }

  Future<void> _irAHistorial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfiguracionScreen(paginaInicial: 2),
      ),
    );
    if (mounted) context.read<TicketProvider>().cargarTicketsHoy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onSettingsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
              ),
            ),
            Expanded(
              child: _DashboardBody(
                onNuevoTicket:  _irABoleteria,
                onVerHistorial: _irAHistorial,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _DashboardBody
// =============================================================================
class _DashboardBody extends StatelessWidget {
  final VoidCallback onNuevoTicket;
  final VoidCallback onVerHistorial;
  const _DashboardBody({
    required this.onNuevoTicket,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    final tickets       = context.select<TicketProvider, List<TicketModel>>((p) => p.ticketsHoy);
    final cargando      = context.select<TicketProvider, bool>((p) => p.cargando);
    final error         = context.select<TicketProvider, String?>((p) => p.error);
    final ticketsActivos = tickets.where((t) => !t.anulado).toList();
    final totalIngresos  = ticketsActivos.fold<double>(0.0, (s, t) => s + t.monto);

    return Column(
      children: [
        if (error != null)
          _ErrorBanner(
            message:  error,
            onDismiss: () => context.read<TicketProvider>().clearError(),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Columna izquierda ──────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Greeting(
                          fecha:    _fmtFecha.format(DateTime.now()),
                          diaLabel: _fmtDia.format(DateTime.now()).toUpperCase(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon:      Icons.confirmation_number_rounded,
                                iconColor: _AppColors.primary,
                                bgColor:   _AppColors.primaryLight,
                                label:     'Tickets Hoy',
                                value:     '${ticketsActivos.length}',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StatCard(
                                icon:      Icons.payments_rounded,
                                iconColor: _AppColors.green,
                                bgColor:   _AppColors.greenLight,
                                label:     'Ingresos Hoy',
                                value:     'S/ ${totalIngresos.toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _PagoDesgloseCard(tickets: ticketsActivos),
                        const SizedBox(height: 14),
                        const _PreciosCard(),
                        const SizedBox(height: 24),
                        _NuevoTicketButton(onTap: onNuevoTicket),
                      ],
                    ),
                  ),
                ),

                // Separador vertical
                Container(
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),

                // ── Columna derecha ────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: _AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _HistorialInline(
                      tickets:        tickets,
                      cargando:       cargando,
                      onVerHistorial: onVerHistorial,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _TopBar
// =============================================================================
class _TopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;
  const _TopBar({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_AppColors.primary, _AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 48, height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EL PARAISO DE ANDAHUASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'SISTEMA DE BOLETERÍA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtFecha.format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _fmtDia.format(DateTime.now()).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
            tooltip: 'Configuración',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _Greeting
// =============================================================================
class _Greeting extends StatelessWidget {
  final String fecha;
  final String diaLabel;
  const _Greeting({required this.fecha, required this.diaLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _AppColors.text,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              fecha,
              style: const TextStyle(fontSize: 14, color: _AppColors.textSoft),
            ),
            const SizedBox(width: 10),
            _DayBadge(label: diaLabel),
          ],
        ),
      ],
    );
  }
}

class _DayBadge extends StatelessWidget {
  final String label;
  const _DayBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// _PreciosCard
// =============================================================================
class _PreciosCard extends StatelessWidget {
  const _PreciosCard();

  @override
  Widget build(BuildContext context) {
    final weekday = DateTime.now().weekday;
    final adulto  = context.select<ConfigProvider, double>((p) => p.precioAdulto(weekday));
    final nino    = context.select<ConfigProvider, double>((p) => p.precioNino(weekday));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TARIFAS VIGENTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _AppColors.textSoft,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TarifaItem(
                  icon: Icons.person_rounded, label: 'Adulto', price: adulto),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TarifaItem(
                  icon: Icons.child_care_rounded, label: 'Niño', price: nino),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarifaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double price;
  const _TarifaItem({
    required this.icon,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: _AppColors.textSoft,
              ),
            ),
            Text(
              'S/ ${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _AppColors.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// _NuevoTicketButton
// =============================================================================
class _NuevoTicketButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NuevoTicketButton({required this.onTap});

  static final _decoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [_AppColors.primary, _AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: const [
      BoxShadow(
        color: Color(0x6600695C),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: _decoration,
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.white, size: 52),
              SizedBox(height: 12),
              Text(
                'Nuevo Ticket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Toca para emitir un nuevo ticket de ingreso',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
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
// _HistorialInline
// =============================================================================
class _HistorialInline extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool cargando;
  final VoidCallback onVerHistorial;
  const _HistorialInline({
    required this.tickets,
    required this.cargando,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: _AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TICKETS DE HOY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _AppColors.text,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _CountBadge(count: tickets.length),
            ],
          ),
        ),
        Expanded(
          child: _HistorialScroll(tickets: tickets, cargando: cargando),
        ),
        _HistorialFooter(onTap: onVerHistorial),
      ],
    );
  }
}

class _HistorialScroll extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool cargando;
  const _HistorialScroll({required this.tickets, required this.cargando});

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (tickets.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: tickets.length,
      itemBuilder: (_, i) => _TicketItem(ticket: tickets[i]),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count EMITIDOS',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: _AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              'Sin tickets hoy',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Los tickets aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _TicketItem
// =============================================================================
class _TicketItem extends StatelessWidget {
  final TicketModel ticket;
  const _TicketItem({required this.ticket});

  Future<void> _mostrarOpciones(BuildContext context) async {
    if (ticket.anulado) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TicketOpcionesDialog(
        ticket: ticket,
        onModificar: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BoleteriaScreen(ticketEditar: ticket),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<TicketProvider>().cargarTicketsHoy();
            }
          });
        },
        onImprimir: () {
          Navigator.pop(ctx);
          _reimprimir(context);
        },
      ),
    );
  }

  Future<void> _reimprimir(BuildContext context) async {
    final cfg    = context.read<ConfigProvider>();
    final weekday = ticket.hora.weekday;

    final precioAdulto = ticket.adultos > 0 && ticket.ninos == 0
        ? ticket.monto / ticket.adultos
        : cfg.precioAdulto(weekday);
    final precioNino = ticket.ninos > 0 && ticket.adultos == 0
        ? ticket.monto / ticket.ninos
        : cfg.precioNino(weekday);

    final nombreImpresora = cfg.nombreImpresora.trim();
    final fmtFecha   = DateFormat('dd/MM/yyyy');
    final fmtHora    = DateFormat('HH:mm');
    final partesPago = ticket.metodoPago.split('+');

    // ── Helpers PDF ───────────────────────────────────────────────────────
    pw.Widget pdfRow(String label, String valor,
        {bool bold = false, double fontSize = 10}) {
      final style = bold
          ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)
          : pw.TextStyle(fontSize: fontSize);
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(label, style: style),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(valor, style: style),
          ),
        ],
      );
    }

    // ── PDF ───────────────────────────────────────────────────────────────
    final pdf  = pw.Document();
    const mmPt = PdfPageFormat.mm;

    // Carga el logo para la marca de agua y la fuente StoryScript (igual que impresión principal)
    final logoData = await rootBundle.load('assets/images/marcaDeAgua.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final storyData = await rootBundle.load('assets/fonts/StoryScript-Regular.ttf');
    final storyFont = pw.Font.ttf(storyData);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat(
            80 * mmPt,
            double.infinity,
            marginLeft: 2 * mmPt,
            marginRight: 2 * mmPt,
            marginTop: 8 * mmPt,
            marginBottom: 8 * mmPt,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.LayoutBuilder(
                builder: (ctx, constraints) => pw.Opacity(
                  opacity: 0.18,
                  child: pw.Image(logoImage, width: math.min(160.0, constraints?.maxWidth ?? 160.0)),
                ),
              ),
            ),
          ),
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Encabezado: logo, título en 2 líneas (StoryScript)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(width: 44, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'CENTRO RECREACIONAL TURISTICO\nEL PARAISO DE ANDAHUASI',
                        style: pw.TextStyle(font: storyFont, fontSize: 13),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 44),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),
            pdfRow('NRO. TICKET:', '#${ticket.ticketId.toString().padLeft(4, '0')}'),
            pw.SizedBox(height: 2),
            pdfRow('FECHA:', fmtFecha.format(ticket.hora)),
            pw.SizedBox(height: 2),
            pdfRow('HORA:', fmtHora.format(ticket.hora)),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 2),
            if (ticket.adultos > 0)
              pdfRow(
                'Adultos S/${precioAdulto.toStringAsFixed(2)} (x${ticket.adultos})',
                'S/ ${(ticket.adultos * precioAdulto).toStringAsFixed(2)}',
              ),
            if (ticket.ninos > 0) ...[  
              pdfRow(
                'Niños S/${precioNino.toStringAsFixed(2)} (x${ticket.ninos})',
                'S/ ${(ticket.ninos * precioNino).toStringAsFixed(2)}',
              ),
            ],
            pw.Divider(thickness: 0.5, height: 2),
            pw.SizedBox(height: 2),
            pdfRow('TOTAL:', 'S/ ${ticket.monto.toStringAsFixed(2)}',
                bold: true, fontSize: 16),
            pw.SizedBox(height: 2),
            pdfRow('Pago:', TicketModel.formatearParte(partesPago[0])),
            if (partesPago.length > 1) ...[
              pw.SizedBox(height: 2),
              pdfRow('', TicketModel.formatearParte(partesPago[1])),
            ],
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Text('Gracias por su visita!',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );

    // ── Impresión ─────────────────────────────────────────────────────────
    try {
      final pdfBytes = await pdf.save();

      if (nombreImpresora.isNotEmpty) {
        final impresoras = await Printing.listPrinters();
        final impresora  = impresoras.firstWhere(
          (p) => p.name == nombreImpresora,
          orElse: () => throw Exception(
            'Impresora "$nombreImpresora" no encontrada.',
          ),
        );
        await Printing.directPrintPdf(
          printer:  impresora,
          onLayout: (_) async => pdfBytes,
        );
      } else {
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket reimpreso correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reimprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarAnulacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Ticket'),
        content: Text(
          '¿Desea anular el ticket #${ticket.ticketId}? '
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
    if (confirmar == true && context.mounted) {
      await context.read<TicketProvider>().anularTicket(ticket.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anulado = ticket.anulado;
    final hora = _fmtHora.format(ticket.hora);
    final totalPax = ticket.adultos + ticket.ninos;
    final metodos = TicketModel.parsearMetodoPago(ticket.metodoPago);
    final esEfectivo = metodos.keys.length == 1 &&
        metodos.keys.first == 'efectivo';

    final cfg = context.read<ConfigProvider>();
    final weekday = ticket.hora.weekday;
    final precioAdulto = ticket.adultos > 0 && ticket.ninos == 0
        ? ticket.monto / ticket.adultos
        : cfg.precioAdulto(weekday);
    final precioNino = ticket.ninos > 0 && ticket.adultos == 0
        ? ticket.monto / ticket.ninos
        : cfg.precioNino(weekday);

    final idBgColor = anulado ? Colors.red.shade50 : _AppColors.primaryLight;
    final idTextColor = anulado ? Colors.red.shade400 : _AppColors.primary;
    final mainTextColor = anulado ? Colors.grey.shade400 : _AppColors.text;
    final badgeBgColor = anulado ? Colors.red.shade50 : _AppColors.greenLight;
    final badgeTextColor = anulado ? Colors.red.shade400 : _AppColors.green;
    final textDecoration = anulado ? TextDecoration.lineThrough : null;

    return GestureDetector(
      onTap: anulado ? null : () => _mostrarOpciones(context),
      onLongPress: anulado ? null : () => _confirmarAnulacion(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: anulado ? AppColors.errorLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: anulado ? Border.all(color: Colors.red.shade200) : null,
          boxShadow: [
            BoxShadow(
              color: (anulado ? Colors.red : _AppColors.primary)
                  .withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: idBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${ticket.ticketId.toString().padLeft(4, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: idTextColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _paxLabel(ticket.adultos, ticket.ninos),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: mainTextColor,
                            decoration: textDecoration,
                          ),
                        ),
                      ),
                      Text(
                        hora,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        esEfectivo ? Icons.money_rounded : Icons.phone_android_rounded,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          metodos.keys.map(TicketModel.formatearParte).join(' + '),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  if (ticket.adultos > 0 || ticket.ninos > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (ticket.adultos > 0)
                          Expanded(
                            child: Text(
                              'Adulto: S/ ${precioAdulto.toStringAsFixed(2)} ×${ticket.adultos}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                        if (ticket.ninos > 0)
                          Expanded(
                            child: Text(
                              'Niño: S/ ${precioNino.toStringAsFixed(2)} ×${ticket.ninos}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),

                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${ticket.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: mainTextColor,
                    decoration: textDecoration,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    anulado ? 'ANULADO' : '$totalPax pax',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _paxLabel(int adultos, int ninos) {
    final parts = <String>[];
    if (adultos > 0) parts.add('$adultos adulto${adultos > 1 ? 's' : ''}');
    if (ninos > 0)   parts.add('$ninos niño${ninos > 1 ? 's' : ''}');
    return parts.join(' + ');
  }
}

// =============================================================================
// _TicketOpcionesDialog
// =============================================================================
class _TicketOpcionesDialog extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onModificar;
  final VoidCallback onImprimir;

  const _TicketOpcionesDialog({
    required this.ticket,
    required this.onModificar,
    required this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${ticket.ticketId.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _TicketItem._paxLabel(ticket.adultos, ticket.ninos),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'S/ ${ticket.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onModificar,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text(
                    'Modificar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onImprimir,
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text(
                    'Imprimir',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(
                        color: _AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: _AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
// _HistorialFooter
// =============================================================================
class _HistorialFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _HistorialFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _AppColors.primaryLight,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 14, color: _AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Ver historial completo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: _AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ErrorBanner
// =============================================================================
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 18, color: Colors.red.shade400),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _PagoDesgloseCard
// =============================================================================
class _PagoDesgloseCard extends StatelessWidget {
  final List<TicketModel> tickets;
  const _PagoDesgloseCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    final porMetodo = <String, double>{};
    for (final t in tickets) {
      final metodos = TicketModel.parsearMetodoPago(t.metodoPago);
      if (metodos.values.every((v) => v != null)) {
        for (final e in metodos.entries) {
          porMetodo[e.key] = (porMetodo[e.key] ?? 0) + e.value!;
        }
      } else {
        final key = metodos.keys.first;
        porMetodo[key] = (porMetodo[key] ?? 0) + t.monto;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESGLOSE POR PAGO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _AppColors.textSoft,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final entry in porMetodo.entries)
                Expanded(
                  child: _TarifaItem(
                    icon: entry.key == 'efectivo'
                        ? Icons.money_rounded
                        : Icons.phone_android_rounded,
                    label: TicketModel.formatearParte(entry.key),
                    price: entry.value,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}