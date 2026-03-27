import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:piscigranja/core/export/export_service.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../../data/models/config_model.dart';
import '../../../tickets/data/models/ticket_model.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

// ─── Constantes de diseño ────────────────────────────────────────────────────
abstract final class _C {
  static const primary      = Color(0xFF0052CC);
  static const primaryLight = Color(0xFFE3F0FF);
  static const greenLight   = Color(0xFFE8F5E9);
  static const green        = Color(0xFF21BA45);
  static const text         = Color(0xFF1A1A1A);
  static const background   = Color(0xFFF0F7FF);
  static const headerBg     = Color(0xFFF8FAFD);
  static const rowAlt       = Color(0xFFFAFBFF);
  static const borderBlue   = Color(0xFFCCE0FF);
  static const orange       = Color(0xFFF2711C);
}

// Formateadores — instanciados una sola vez
final _fmtResumen  = DateFormat("dd MMM, yyyy", 'es');
final _fmtFechaRow = DateFormat("dd MMM, yyyy", 'es');
final _fmtHoraRow  = DateFormat('hh:mm a');

// Metadatos por día de semana (índice 0 = Lunes)
const _dayIcons = [
  Icons.work_outline_rounded,
  Icons.work_outline_rounded,
  Icons.work_outline_rounded,
  Icons.work_outline_rounded,
  Icons.work_outline_rounded,
  Icons.wb_sunny_rounded,
  Icons.wb_sunny_rounded,
];
const _dayColors = [
  _C.primary, _C.primary, _C.primary, _C.primary, _C.primary,
  _C.orange,  _C.orange,
];

// =============================================================================
// ConfiguracionScreen
// =============================================================================
class ConfiguracionScreen extends StatefulWidget {
  final int paginaInicial;
  const ConfiguracionScreen({super.key, this.paginaInicial = 0});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<TextEditingController> _adultoCtrls;
  late final List<TextEditingController> _ninoCtrls;
  late final TextEditingController _impresoraCtrl;

  DateTime _desde              = DateTime.now();
  DateTime _hasta              = DateTime.now();
  List<TicketModel> _historial = [];
  bool _historialCargando      = false;

  late final int _diaHoy = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.paginaInicial,
    );
    final cfg = context.read<ConfigProvider>().config;
    _adultoCtrls = List.generate(
      7, (i) => TextEditingController(text: cfg.preciosAdulto[i].toStringAsFixed(2)),
    );
    _ninoCtrls = List.generate(
      7, (i) => TextEditingController(text: cfg.preciosNino[i].toStringAsFixed(2)),
    );
    _impresoraCtrl = TextEditingController(text: cfg.nombreImpresora);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [..._adultoCtrls, ..._ninoCtrls]) c.dispose();
    _impresoraCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color bg = _C.primary}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  void _ajustar(TextEditingController ctrl, double delta) {
    final current = double.tryParse(ctrl.text) ?? 0;
    ctrl.text = (current + delta).clamp(0.0, 9999.0).toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _guardarPrecios() async {
    final adultos = _adultoCtrls.map((c) => double.tryParse(c.text) ?? 0).toList();
    final ninos   = _ninoCtrls.map((c) => double.tryParse(c.text) ?? 0).toList();
    if (adultos.any((p) => p <= 0) || ninos.any((p) => p <= 0)) {
      _showSnack('Todos los precios deben ser mayores a 0', bg: Colors.orange);
      return;
    }
    await context.read<ConfigProvider>().actualizarPrecios(
      preciosAdulto: adultos,
      preciosNino:   ninos,
    );
    _showSnack('Precios guardados');
  }

  Future<void> _guardarImpresora() async {
    await context.read<ConfigProvider>().actualizarImpresora(
      _impresoraCtrl.text.trim(),
    );
    _showSnack('Impresora guardada');
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final inicial = esDesde ? _desde : _hasta;
    final fecha   = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (fecha == null) return;
    setState(() {
      if (esDesde) {
        _desde = fecha;
        if (_desde.isAfter(_hasta)) _hasta = _desde;
      } else {
        _hasta = fecha;
        if (_hasta.isBefore(_desde)) _desde = _hasta;
      }
    });
    await _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _historialCargando = true);
    try {
      _historial = await context
          .read<TicketProvider>()
          .obtenerTicketsPorRango(_desde, _hasta);
    } catch (_) {
      _historial = [];
    } finally {
      if (mounted) setState(() => _historialCargando = false);
    }
  }

  Future<void> _anularDesdeHistorial(TicketModel ticket) async {
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
    if (confirmar == true && mounted) {
      await context.read<TicketProvider>().anularTicket(ticket.id);
      await _cargarHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        title: const Text('Configuración',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.sell_rounded),    text: 'Precios'),
            Tab(icon: Icon(Icons.print_rounded),   text: 'Impresora'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabPrecios(
            diaHoy:      _diaHoy,
            adultoCtrls: _adultoCtrls,
            ninoCtrls:   _ninoCtrls,
            onAjustar:   _ajustar,
            onGuardar:   _guardarPrecios,
          ),
          _TabImpresora(
            ctrl:      _impresoraCtrl,
            onGuardar: _guardarImpresora,
          ),
          _TabHistorial(
            desde:     _desde,
            hasta:     _hasta,
            historial: _historial,         // ✅ lista real, no []
            cargando:  _historialCargando,
            onSelDesde: () => _seleccionarFecha(true),
            onSelHasta: () => _seleccionarFecha(false),
            onBuscar:   _cargarHistorial,
            onAnular:   _anularDesdeHistorial,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab Precios
// =============================================================================
class _TabPrecios extends StatelessWidget {
  final int diaHoy;
  final List<TextEditingController> adultoCtrls;
  final List<TextEditingController> ninoCtrls;
  final void Function(TextEditingController, double) onAjustar;
  final VoidCallback onGuardar;

  const _TabPrecios({
    required this.diaHoy,
    required this.adultoCtrls,
    required this.ninoCtrls,
    required this.onAjustar,
    required this.onGuardar,
  });

  static final _saveStyle = ElevatedButton.styleFrom(
    backgroundColor: _C.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 4,
  );

  Widget _diaCard(int i) => _DiaCard(
        nombreDia:  ConfigModel.nombresDias[i],
        icono:      _dayIcons[i],
        color:      _dayColors[i],
        adultoCtrl: adultoCtrls[i],
        ninoCtrl:   ninoCtrls[i],
        onAjustar:  onAjustar,
        esHoy:      diaHoy == i,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: _diaCard(i)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int j = 0; j < 3; j++) ...[
                        if (j > 0) const SizedBox(width: 12),
                        Expanded(child: _diaCard(j + 4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: SizedBox(
            height: 62,
            child: ElevatedButton.icon(
              onPressed: onGuardar,
              icon: const Icon(Icons.save_rounded, size: 26),
              label: const Text(
                'GUARDAR PRECIOS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              style: _saveStyle,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tab Impresora
// =============================================================================
class _TabImpresora extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onGuardar;

  const _TabImpresora({required this.ctrl, required this.onGuardar});

  static final _saveStyle = ElevatedButton.styleFrom(
    backgroundColor: _C.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          _ConfigCard(
            titulo:      'Nombre de la impresora',
            descripcion: 'Ingresa el nombre exacto del dispositivo',
            icono:       Icons.print_rounded,
            child: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Ej: POS-80C, EPSON TM-T20',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _C.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGuardar,
            icon: const Icon(Icons.save_rounded),
            label: const Text(
              'GUARDAR IMPRESORA',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
            style: _saveStyle,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab Historial
// =============================================================================
class _TabHistorial extends StatelessWidget {
  final DateTime desde;
  final DateTime hasta;
  final List<TicketModel> historial;
  final bool cargando;
  final VoidCallback onSelDesde;
  final VoidCallback onSelHasta;
  final VoidCallback onBuscar;
  final void Function(TicketModel) onAnular;

  const _TabHistorial({
    required this.desde,
    required this.hasta,
    required this.historial,
    required this.cargando,
    required this.onSelDesde,
    required this.onSelHasta,
    required this.onBuscar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final activos       = historial.where((t) => !t.anulado).toList();
    final totalIngresos = activos.fold<double>(0, (s, t) => s + t.monto);
    final totalPersonas = activos.fold<int>(0, (s, t) => s + t.adultos + t.ninos);
    final totalAnulados = historial.where((t) => t.anulado).length;
    final hayDatos      = historial.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ Se pasa historial real para que los botones de exportar aparezcan
        _HistorialHeader(
          desde:     desde,
          hasta:     hasta,
          historial: historial,
          onDesde:   onSelDesde,
          onHasta:   onSelHasta,
          onBuscar:  onBuscar,
        ),

        if (hayDatos)
          _ResumenRow(
            totalTickets:  activos.length,
            totalPersonas: totalPersonas,
            totalIngresos: totalIngresos,
            totalAnulados: totalAnulados,
          ),

        const SizedBox(height: 8),

        Expanded(
          child: _HistorialTabla(
            historial: historial,
            cargando:  cargando,
            onAnular:  onAnular,
          ),
        ),
      ],
    );
  }
}

// ── Encabezado de búsqueda ────────────────────────────────────────────────────
class _HistorialHeader extends StatelessWidget {
  final DateTime desde, hasta;
  final List<TicketModel> historial;
  final VoidCallback onDesde, onHasta, onBuscar;

  const _HistorialHeader({
    required this.desde,
    required this.hasta,
    required this.historial,
    required this.onDesde,
    required this.onHasta,
    required this.onBuscar,
  });

  static final _buscarStyle = ElevatedButton.styleFrom(
    backgroundColor: _C.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Row(
        children: [
          // Título (izquierda)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de Tickets',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _C.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta y gestiona el registro histórico de ventas.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Botones de exportación (CSV, PDF, Buscar) - izquierda de las fechas
          if (historial.isNotEmpty) ...[
            _ExportButton(
              icon:  Icons.table_chart_rounded,
              label: 'CSV',
              color: const Color(0xFF21BA45),
              onTap: () => ExportService.instance.exportarCSV(
                tickets: historial,
                desde:   desde,
                hasta:   hasta,
                context: context,
              ),
              large: true,
            ),
            const SizedBox(width: 10),
            _ExportButton(
              icon:  Icons.picture_as_pdf_rounded,
              label: 'PDF',
              color: Colors.red,
              onTap: () => ExportService.instance.exportarPDF(
                tickets: historial,
                desde:   desde,
                hasta:   hasta,
                context: context,
              ),
              large: true,
            ),
            const SizedBox(width: 10),
          ],

          ElevatedButton.icon(
            onPressed: onBuscar,
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text(
              'Buscar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: _buscarStyle,
          ),

          const SizedBox(width: 16),

          // Rango de fechas (derecha)
          Row(
            children: [
              _FechaChip(
                label: 'DESDE',
                fecha: _fmtResumen.format(desde),
                onTap: onDesde,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: _C.primary),
              ),
              _FechaChip(
                label: 'HASTA',
                fecha: _fmtResumen.format(hasta),
                onTap: onHasta,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Fila de tarjetas resumen ──────────────────────────────────────────────────
class _ResumenRow extends StatelessWidget {
  final int totalTickets, totalPersonas, totalAnulados;
  final double totalIngresos;

  const _ResumenRow({
    required this.totalTickets,
    required this.totalPersonas,
    required this.totalIngresos,
    required this.totalAnulados,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icono:   Icons.confirmation_number_rounded,
              label:   'TOTAL TICKETS',
              valor:   '$totalTickets',
              color:   _C.primary,
              bgColor: _C.primaryLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              icono:   Icons.people_rounded,
              label:   'TOTAL PERSONAS',
              valor:   '$totalPersonas',
              color:   _C.primary,
              bgColor: _C.primaryLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              icono:   Icons.payments_rounded,
              label:   'INGRESO TOTAL',
              valor:   'S/ ${totalIngresos.toStringAsFixed(2)}',
              color:   _C.primary,
              bgColor: _C.primaryLight,
            ),
          ),
          if (totalAnulados > 0) ...[
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                icono:   Icons.cancel_rounded,
                label:   'ANULADOS',
                valor:   '$totalAnulados',
                color:   Colors.red.shade600,
                bgColor: Colors.red.shade50,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tabla con cabecera, contenido y pie ──────────────────────────────────────
class _HistorialTabla extends StatelessWidget {
  final List<TicketModel> historial;
  final bool cargando;
  final void Function(TicketModel) onAnular;

  const _HistorialTabla({
    required this.historial,
    required this.cargando,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final hayDatos = historial.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            if (hayDatos) ...[
              const _TablaHeader(),
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            ],

            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : !hayDatos
                      ? const _TablaVacia()
                      : ListView.separated(
                          itemCount: historial.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100,
                          ),
                          itemBuilder: (_, i) => _HistorialRow(
                            ticket:   historial[i],
                            isEven:   i.isEven,
                            onAnular: onAnular,
                          ),
                        ),
            ),

            if (hayDatos) _TablaPie(count: historial.length),
          ],
        ),
      ),
    );
  }
}

class _TablaHeader extends StatelessWidget {
  const _TablaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _ThLabel(text: 'ID TICKET')),
          Expanded(flex: 3, child: _ThLabel(text: 'FECHA / HORA')),
          Expanded(flex: 4, child: _ThLabel(text: 'DETALLE (PAX)')),
          Expanded(flex: 3, child: _ThLabel(text: 'PAGO')),
          Expanded(flex: 3, child: _ThLabel(text: 'MONTO',   right: true)),
          Expanded(flex: 2, child: _ThLabel(text: 'ESTADO',  right: true)),
          Expanded(flex: 2, child: _ThLabel(text: 'ACCIONES',right: true)),
        ],
      ),
    );
  }
}

class _TablaVacia extends StatelessWidget {
  const _TablaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Seleccione un rango de fechas y presione Buscar',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TablaPie extends StatelessWidget {
  final int count;
  const _TablaPie({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _C.headerBg,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Text(
        'Mostrando $count ticket${count != 1 ? 's' : ''}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    );
  }
}

// ── Fila individual de historial ──────────────────────────────────────────────
class _HistorialRow extends StatelessWidget {
  final TicketModel ticket;
  final bool isEven;
  final void Function(TicketModel) onAnular;

  const _HistorialRow({
    required this.ticket,
    required this.isEven,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final t           = ticket;
    final anulado     = t.anulado;
    final horaFmt     = _fmtHoraRow.format(t.hora);
    final fechaFmt    = _fmtFechaRow.format(t.hora);
    final esEfectivo  = t.metodoPago == 'efectivo';

    final idColor         = anulado ? Colors.red.shade300 : _C.primary;
    final montoColor      = anulado ? Colors.grey.shade400 : _C.text;
    final estadoBgColor   = anulado ? Colors.red.shade50 : _C.greenLight;
    final estadoColor     = anulado ? Colors.red.shade400 : _C.green;
    final bgColor         = anulado
        ? const Color(0xFFFFF5F5)
        : (isEven ? Colors.white : _C.rowAlt);
    final montoDecoration = anulado ? TextDecoration.lineThrough : null;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '#TK-${t.ticketId}',
              style: TextStyle(
                  color: idColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fechaFmt,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _C.text)),
                Text(horaFmt,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (t.adultos > 0)
                  _PaxBadge(
                    label:   '${t.adultos} Adulto${t.adultos > 1 ? 's' : ''}',
                    color:   _C.primary,
                    bgColor: _C.primaryLight,
                  ),
                if (t.adultos > 0 && t.ninos > 0) const SizedBox(width: 6),
                if (t.ninos > 0)
                  _PaxBadge(
                    label:   '${t.ninos} Niño${t.ninos > 1 ? 's' : ''}',
                    color:   _C.green,
                    bgColor: _C.greenLight,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  esEfectivo ? Icons.payments_rounded : Icons.phone_android_rounded,
                  size: 16, color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '${t.metodoPago[0].toUpperCase()}${t.metodoPago.substring(1)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'S/ ${t.monto.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: montoColor,
                decoration: montoDecoration,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: estadoColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      anulado ? 'Anulado' : 'Completado',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: estadoColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: anulado
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () => onAnular(ticket),
                      icon: Icon(Icons.cancel_outlined,
                          size: 20, color: Colors.red.shade300),
                      tooltip: 'Anular ticket',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge de pasajero ─────────────────────────────────────────────────────────
class _PaxBadge extends StatelessWidget {
  final String label;
  final Color color, bgColor;
  const _PaxBadge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// =============================================================================
// Widgets reutilizables
// =============================================================================

class _FechaChip extends StatelessWidget {
  final String label, fecha;
  final VoidCallback onTap;
  const _FechaChip(
      {required this.label, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _C.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.borderBlue, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _C.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                        letterSpacing: 0.8)),
                const SizedBox(height: 3),
                Text(fecha,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icono;
  final String label, valor;
  final Color color, bgColor;

  const _SummaryCard({
    required this.icono,
    required this.label,
    required this.valor,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.7),
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(valor,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThLabel extends StatelessWidget {
  final String text;
  final bool right;
  const _ThLabel({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}

// =============================================================================
// _DiaCard
// =============================================================================
class _DiaCard extends StatelessWidget {
  final String nombreDia;
  final IconData icono;
  final Color color;
  final TextEditingController adultoCtrl, ninoCtrl;
  final void Function(TextEditingController, double) onAjustar;
  final bool esHoy;

  const _DiaCard({
    required this.nombreDia,
    required this.icono,
    required this.color,
    required this.adultoCtrl,
    required this.ninoCtrl,
    required this.onAjustar,
    this.esHoy = false,
  });

  static const _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  @override
  Widget build(BuildContext context) {
    final labelColor = Colors.blueGrey.shade500;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: esHoy ? 0.28 : 0.10),
            blurRadius: esHoy ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: esHoy ? color : color.withValues(alpha: 0.18),
          width: esHoy ? 2.5 : 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: esHoy ? color : color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icono, color: esHoy ? Colors.white : color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombreDia,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: esHoy ? Colors.white : color,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (esHoy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('HOY',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.2)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('PRECIO ADULTO', style: _labelStyle.copyWith(color: labelColor)),
          const SizedBox(height: 6),
          _FilaPrecio(ctrl: adultoCtrl, color: color, onAjustar: onAjustar),
          const SizedBox(height: 10),
          Text('PRECIO NIÑO', style: _labelStyle.copyWith(color: labelColor)),
          const SizedBox(height: 6),
          _FilaPrecio(ctrl: ninoCtrl, color: color, onAjustar: onAjustar),
        ],
      ),
    );
  }
}

// =============================================================================
// _FilaPrecio
// =============================================================================
class _FilaPrecio extends StatelessWidget {
  final TextEditingController ctrl;
  final Color color;
  final void Function(TextEditingController, double) onAjustar;

  const _FilaPrecio({
    required this.ctrl,
    required this.color,
    required this.onAjustar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BtnPrecio(
          icono: Icons.remove_rounded,
          color: color,
          onTap: () => onAjustar(ctrl, -0.5),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              border: Border.all(
                  color: color.withValues(alpha: 0.35), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Text('S/',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18, color: color),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _BtnPrecio(
          icono: Icons.add_rounded,
          color: color,
          onTap: () => onAjustar(ctrl, 0.5),
        ),
      ],
    );
  }
}

// =============================================================================
// _BtnPrecio
// =============================================================================
class _BtnPrecio extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BtnPrecio({
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icono, color: Colors.white, size: 22),
      ),
    );
  }
}

// =============================================================================
// _ConfigCard
// =============================================================================
class _ConfigCard extends StatelessWidget {
  final String titulo, descripcion;
  final IconData icono;
  final Widget child;

  const _ConfigCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: _C.primary, size: 22),
              const SizedBox(width: 10),
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(descripcion,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// _ExportButton
// =============================================================================
class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 20.0 : 18.0;
    final fontSize = large ? 15.0 : 14.0;
    final verticalPadding = large ? 16.0 : 14.0;
    final horizontalPadding = large ? 22.0 : 18.0;

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: iconSize),
      label: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
