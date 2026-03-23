import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../../data/models/config_model.dart';
import '../../../tickets/data/models/ticket_model.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  final int paginaInicial;
  const ConfiguracionScreen({super.key, this.paginaInicial = 0});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<TextEditingController> _adultoCtrls;
  late List<TextEditingController> _ninoCtrls;
  late TextEditingController _impresoraCtrl;

  // Historial state
  DateTime _desde = DateTime.now();
  DateTime _hasta = DateTime.now();
  List<TicketModel> _historialTickets = [];
  bool _historialCargando = false;

  static const _dayIcons = [
    Icons.work_outline_rounded,
    Icons.work_outline_rounded,
    Icons.work_outline_rounded,
    Icons.work_outline_rounded,
    Icons.work_outline_rounded,
    Icons.wb_sunny_rounded,
    Icons.wb_sunny_rounded,
  ];

  static const _dayColors = [
    Color(0xFF0052CC),
    Color(0xFF0052CC),
    Color(0xFF0052CC),
    Color(0xFF0052CC),
    Color(0xFF0052CC),
    Color(0xFFF2711C),
    Color(0xFFF2711C),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.paginaInicial);
    final cfg = context.read<ConfigProvider>().config;
    _adultoCtrls = List.generate(
        7, (i) => TextEditingController(text: cfg.preciosAdulto[i].toStringAsFixed(2)));
    _ninoCtrls = List.generate(
        7, (i) => TextEditingController(text: cfg.preciosNino[i].toStringAsFixed(2)));
    _impresoraCtrl = TextEditingController(text: cfg.nombreImpresora);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _adultoCtrls) {
      c.dispose();
    }
    for (final c in _ninoCtrls) {
      c.dispose();
    }
    _impresoraCtrl.dispose();
    super.dispose();
  }

  void _ajustar(TextEditingController ctrl, double delta) {
    final current = double.tryParse(ctrl.text) ?? 0;
    final nuevo = (current + delta).clamp(0.0, 9999.0);
    ctrl.text = nuevo.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _guardarPrecios() async {
    final adultos = _adultoCtrls.map((c) => double.tryParse(c.text) ?? 0).toList();
    final ninos = _ninoCtrls.map((c) => double.tryParse(c.text) ?? 0).toList();
    if (adultos.any((p) => p <= 0) || ninos.any((p) => p <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Todos los precios deben ser mayores a 0')));
      return;
    }
    await context
        .read<ConfigProvider>()
        .actualizarPrecios(preciosAdulto: adultos, preciosNino: ninos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Precios guardados'),
        backgroundColor: Color(0xFF0052CC)));
  }

  Future<void> _guardarImpresora() async {
    await context
        .read<ConfigProvider>()
        .actualizarImpresora(_impresoraCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impresora guardada'),
        backgroundColor: Color(0xFF0052CC)));
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final inicial = esDesde ? _desde : _hasta;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _desde = fecha;
          if (_desde.isAfter(_hasta)) _hasta = _desde;
        } else {
          _hasta = fecha;
          if (_hasta.isBefore(_desde)) _desde = _hasta;
        }
      });
      _cargarHistorial();
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() => _historialCargando = true);
    try {
      _historialTickets = await context
          .read<TicketProvider>()
          .obtenerTicketsPorRango(_desde, _hasta);
    } catch (_) {
      _historialTickets = [];
    }
    if (mounted) setState(() => _historialCargando = false);
  }

  Future<void> _anularDesdeHistorial(TicketModel ticket) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Ticket'),
        content: Text(
            '¿Desea anular el ticket #${ticket.ticketId}? Esta acción no se puede deshacer.'),
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
      _cargarHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        title: const Text('Configuración',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.sell_rounded), text: 'Precios'),
            Tab(icon: Icon(Icons.print_rounded), text: 'Impresora'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          //  Tab Precios 
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fila 1: Lunes – Jueves
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(4, (i) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                              child: _DiaCard(
                                nombreDia: ConfigModel.nombresDias[i],
                                icono: _dayIcons[i],
                                color: _dayColors[i],
                                adultoCtrl: _adultoCtrls[i],
                                ninoCtrl: _ninoCtrls[i],
                                onAjustar: _ajustar,
                                esHoy: DateTime.now().weekday - 1 == i,
                              ),
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Fila 2: Viernes – Domingo
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(3, (j) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: j == 0 ? 0 : 12),
                              child: _DiaCard(
                                nombreDia: ConfigModel.nombresDias[j + 4],
                                icono: _dayIcons[j + 4],
                                color: _dayColors[j + 4],
                                adultoCtrl: _adultoCtrls[j + 4],
                                ninoCtrl: _ninoCtrls[j + 4],
                                onAjustar: _ajustar,
                                esHoy: DateTime.now().weekday - 1 == j + 4,
                              ),
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 62, // altura fija generosa
                child: ElevatedButton.icon(
                  onPressed: _guardarPrecios,
                  icon: const Icon(Icons.save_rounded, size: 26),
                  label: const Text(
                    'GUARDAR PRECIOS',
                    style: TextStyle(
                      fontSize: 18,             // era implícito ~14
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF0052CC).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            ],
          ),
          //  Tab Impresora 
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                _ConfigCard(
                  titulo: 'Nombre de la impresora',
                  descripcion: 'Ingresa el nombre exacto del dispositivo',
                  icono: Icons.print_rounded,
                  child: TextField(
                    controller: _impresoraCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: POS-80C, EPSON TM-T20',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF0052CC), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _guardarImpresora,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('GUARDAR IMPRESORA',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          //  Tab Historial 
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildHistorialTab() {
    final fmt = DateFormat("dd MMM, yyyy", 'es');
    final ticketsActivos =
        _historialTickets.where((t) => !t.anulado).toList();
    final totalIngresos =
        ticketsActivos.fold<double>(0, (s, t) => s + t.monto);
    final totalPersonas =
        ticketsActivos.fold<int>(0, (s, t) => s + t.adultos + t.ninos);
    final totalAnulados =
        _historialTickets.where((t) => t.anulado).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Encabezado: título + fechas + buscar ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Título
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historial de Tickets',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 4),
                        Text(
                            'Consulta y gestiona el registro histórico de ventas.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  // Fecha DESDE
                  _FechaChip(
                    label: 'DESDE',
                    fecha: fmt.format(_desde),
                    onTap: () => _seleccionarFecha(true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Color(0xFF0052CC)),
                  ),
                  // Fecha HASTA
                  _FechaChip(
                    label: 'HASTA',
                    fecha: fmt.format(_hasta),
                    onTap: () => _seleccionarFecha(false),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _cargarHistorial,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Buscar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Tarjetas resumen ──
        if (_historialTickets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icono: Icons.confirmation_number_rounded,
                    label: 'TOTAL TICKETS',
                    valor: '${ticketsActivos.length}',
                    color: const Color(0xFF0052CC),
                    bgColor: const Color(0xFFE3F0FF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    icono: Icons.people_rounded,
                    label: 'TOTAL PERSONAS',
                    valor: '$totalPersonas',
                    color: const Color(0xFF0052CC),
                    bgColor: const Color(0xFFE3F0FF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    icono: Icons.payments_rounded,
                    label: 'INGRESO TOTAL',
                    valor: 'S/ ${totalIngresos.toStringAsFixed(2)}',
                    color: const Color(0xFF0052CC),
                    bgColor: const Color(0xFFE3F0FF),
                  ),
                ),
                if (totalAnulados > 0) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SummaryCard(
                      icono: Icons.cancel_rounded,
                      label: 'ANULADOS',
                      valor: '$totalAnulados',
                      color: Colors.red.shade600,
                      bgColor: Colors.red.shade50,
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── Tabla ──
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Cabecera tabla
                  if (_historialTickets.isNotEmpty)
                    Container(
                      color: const Color(0xFFF8FAFD),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: _ThLabel(text: 'ID TICKET')),
                          Expanded(
                              flex: 3,
                              child: _ThLabel(text: 'FECHA / HORA')),
                          Expanded(
                              flex: 4,
                              child: _ThLabel(text: 'DETALLE (PAX)')),
                          Expanded(
                              flex: 3, child: _ThLabel(text: 'PAGO')),
                          Expanded(
                              flex: 3,
                              child: _ThLabel(
                                  text: 'MONTO', right: true)),
                          Expanded(
                              flex: 2,
                              child: _ThLabel(
                                  text: 'ESTADO', right: true)),
                          Expanded(
                              flex: 2,
                              child: _ThLabel(
                                  text: 'ACCIONES', right: true)),
                        ],
                      ),
                    ),
                  if (_historialTickets.isNotEmpty)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200),
                  // Contenido
                  if (_historialCargando)
                    const Expanded(
                        child: Center(
                            child: CircularProgressIndicator()))
                  else if (_historialTickets.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 56,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                                'Seleccione un rango de fechas y presione Buscar',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _historialTickets.length,
                        separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100),
                        itemBuilder: (context, i) {
                          final t = _historialTickets[i];
                          final horaFmt = DateFormat('hh:mm a').format(t.hora);
                          final fechaFmt =
                              DateFormat("dd MMM, yyyy", 'es').format(t.hora);
                          final esEfectivo =
                              t.metodoPago == 'efectivo';
                          final iconoPago = esEfectivo
                              ? Icons.payments_rounded
                              : Icons.phone_android_rounded;

                          return Container(
                            color: t.anulado
                                ? const Color(0xFFFFF5F5)
                                : (i.isEven
                                    ? Colors.white
                                    : const Color(0xFFFAFBFF)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                // ID
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '#TK-${t.ticketId}',
                                    style: TextStyle(
                                        color: t.anulado
                                            ? Colors.red.shade300
                                            : const Color(0xFF0052CC),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                // Fecha / Hora
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fechaFmt,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A))),
                                      Text(horaFmt,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                // Detalle (PAX) - badges
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      if (t.adultos > 0)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                const Color(0xFFE3F0FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${t.adultos} Adulto${t.adultos > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    Color(0xFF0052CC)),
                                          ),
                                        ),
                                      if (t.adultos > 0 && t.ninos > 0)
                                        const SizedBox(width: 6),
                                      if (t.ninos > 0)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${t.ninos} Niño${t.ninos > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    Color(0xFF21BA45)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Pago
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Icon(iconoPago,
                                          size: 16,
                                          color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.metodoPago[0].toUpperCase() +
                                            t.metodoPago.substring(1),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                // Monto
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'S/ ${t.monto.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: t.anulado
                                            ? Colors.grey.shade400
                                            : const Color(0xFF1A1A1A),
                                        decoration: t.anulado
                                            ? TextDecoration.lineThrough
                                            : null),
                                  ),
                                ),
                                // Estado
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.anulado
                                            ? Colors.red.shade50
                                            : const Color(0xFFE8F5E9),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: t.anulado
                                                  ? Colors.red.shade400
                                                  : const Color(
                                                      0xFF21BA45),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            t.anulado
                                                ? 'Anulado'
                                                : 'Completado',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: t.anulado
                                                    ? Colors.red.shade400
                                                    : const Color(
                                                        0xFF21BA45)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Acciones
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      if (!t.anulado)
                                        IconButton(
                                          onPressed: () =>
                                              _anularDesdeHistorial(t),
                                          icon: Icon(
                                              Icons.cancel_outlined,
                                              size: 20,
                                              color:
                                                  Colors.red.shade300),
                                          tooltip: 'Anular ticket',
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  // Pie de tabla
                  if (_historialTickets.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade200, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Mostrando ${_historialTickets.length} ticket${_historialTickets.length != 1 ? 's' : ''}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FechaChip extends StatelessWidget {
  final String label;
  final String fecha;
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
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCE0FF), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: Color(0xFF0052CC)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0052CC),
                        letterSpacing: 0.8)),
                const SizedBox(height: 3),
                Text(fecha,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
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
  final String label;
  final String valor;
  final Color color;
  final Color bgColor;
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
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color)),
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
    return Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5));
  }
}

//  Tarjeta por día 

class _DiaCard extends StatelessWidget {
  final String nombreDia;
  final IconData icono;
  final Color color;
  final TextEditingController adultoCtrl;
  final TextEditingController ninoCtrl;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: esHoy ? color.withValues(alpha: 0.28) : color.withValues(alpha: 0.10),
              blurRadius: esHoy ? 18 : 10,
              offset: const Offset(0, 5))
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
          //  Cabecera del día 
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
                        letterSpacing: 0.3),
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
          Text('PRECIO ADULTO',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade500,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _FilaPrecio(ctrl: adultoCtrl, color: color, onAjustar: onAjustar),
          const SizedBox(height: 10),
          Text('PRECIO NIÑO',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade500,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _FilaPrecio(ctrl: ninoCtrl, color: color, onAjustar: onAjustar),
        ],
      ),
    );
  }
}


class _FilaPrecio extends StatelessWidget {
  final TextEditingController ctrl;
  final Color color;
  final void Function(TextEditingController, double) onAjustar;

  const _FilaPrecio(
      {required this.ctrl, required this.color, required this.onAjustar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BtnPrecio(
            icono: Icons.remove_rounded,
            color: color,
            onTap: () => onAjustar(ctrl, -0.5)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: color),
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
            onTap: () => onAjustar(ctrl, 0.5)),
      ],
    );
  }
}

class _BtnPrecio extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BtnPrecio(
      {required this.icono, required this.color, required this.onTap});

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
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icono, color: Colors.white, size: 22),
      ),
    );
  }
}

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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: const Color(0xFF0052CC), size: 22),
            const SizedBox(width: 10),
            Text(titulo,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text(descripcion,
              style:
                  const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

