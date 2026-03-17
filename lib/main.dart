import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ╔══════════════════════════════════════╗
//  MODELO — HISTORIAL DE TICKETS
// ╚══════════════════════════════════════╝
class TicketRecord {
  final int id;
  final int adultos;
  final int ninos;
  final double monto;
  final DateTime hora;
  TicketRecord({
    required this.id,
    required this.adultos,
    required this.ninos,
    required this.monto,
    required this.hora,
  });
}

class TicketHistorial {
  TicketHistorial._();
  static final TicketHistorial instance = TicketHistorial._();

  final List<TicketRecord> _registros = [];
  DateTime? _fechaActual;
  int _contador = 84000 + (DateTime.now().millisecondsSinceEpoch % 1000);

  List<TicketRecord> get registros {
    _resetearSiNuevoDia();
    return List.unmodifiable(_registros);
  }

  TicketRecord agregar({
    required int adultos,
    required int ninos,
    required double monto,
  }) {
    _resetearSiNuevoDia();
    final rec = TicketRecord(
      id: _contador++,
      adultos: adultos,
      ninos: ninos,
      monto: monto,
      hora: DateTime.now(),
    );
    _registros.insert(0, rec);
    return rec;
  }

  void _resetearSiNuevoDia() {
    final hoy = DateTime.now();
    final fecha = DateTime(hoy.year, hoy.month, hoy.day);
    if (_fechaActual == null || _fechaActual != fecha) {
      _registros.clear();
      _fechaActual = fecha;
    }
  }
}

// ╔══════════════════════════════════════╗
//  CONFIGURACIÓN GLOBAL
// ╚══════════════════════════════════════╝
class AppConfig extends ChangeNotifier {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  double precioAdultoSemana = 8.0;
  double precioAdultoFinde = 10.0;
  double precioNinoSemana = 5.0;
  double precioNinoFinde = 7.0;
  String nombreImpresora = '';

  void actualizarPrecios({
    required double adultoSemana,
    required double adultoFinde,
    required double ninoSemana,
    required double ninoFinde,
  }) {
    precioAdultoSemana = adultoSemana;
    precioAdultoFinde = adultoFinde;
    precioNinoSemana = ninoSemana;
    precioNinoFinde = ninoFinde;
    notifyListeners();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PiscigranjaApp());
}

// ╔══════════════════════════════════════╗
//  APP ROOT
// ╚══════════════════════════════════════╝
class PiscigranjaApp extends StatelessWidget {
  const PiscigranjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piscigranja — Boletería',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BoleteriaScreen(),
    );
  }
}

// ╔══════════════════════════════════════╗
//  PANTALLA PRINCIPAL — BOLETERÍA
// ╚══════════════════════════════════════╝
class BoleteriaScreen extends StatefulWidget {
  const BoleteriaScreen({super.key});
  @override
  State<BoleteriaScreen> createState() => _BoleteriaScreenState();
}

class _BoleteriaScreenState extends State<BoleteriaScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int adultos = 0;
  int ninos = 0;
  String metodoPago = 'efectivo';
  final TextEditingController _montoCtrl = TextEditingController();
  double _vuelto = 0;
  bool _montoInsuficiente = false;
  bool _ticketRegistrado = false;

  void _onConfigChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppConfig.instance.addListener(_onConfigChange);
  }

  bool get _esFinde => DateTime.now().weekday >= 6;

  double get _precioAdulto => _esFinde
      ? AppConfig.instance.precioAdultoFinde
      : AppConfig.instance.precioAdultoSemana;

  double get _precioNino => _esFinde
      ? AppConfig.instance.precioNinoFinde
      : AppConfig.instance.precioNinoSemana;

  double get _total => adultos * _precioAdulto + ninos * _precioNino;

  void _calcularVuelto() {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    setState(() {
      _vuelto = monto - _total;
      _montoInsuficiente = monto > 0 && _vuelto < 0;
    });
  }

  @override
  void dispose() {
    AppConfig.instance.removeListener(_onConfigChange);
    _montoCtrl.dispose();
    super.dispose();
  }

  void _resetear() {
    setState(() {
      adultos = 0;
      ninos = 0;
      metodoPago = 'efectivo';
      _montoCtrl.clear();
      _vuelto = 0;
      _montoInsuficiente = false;
      _ticketRegistrado = false;
    });
  }

  void _irAPreview() {
    if (adultos + ninos == 0) return;
    if (!_ticketRegistrado) {
      TicketHistorial.instance.agregar(
        adultos: adultos,
        ninos: ninos,
        monto: _total,
      );
      _ticketRegistrado = true;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPreviewScreen(
          adultos: adultos,
          ninos: ninos,
          precioAdulto: _precioAdulto,
          precioNino: _precioNino,
          total: _total,
          metodoPago: metodoPago,
          montoEntregado: double.tryParse(_montoCtrl.text) ?? 0,
          vuelto: _vuelto,
          onSalir: _resetear,
        ),
      ),
    );
  }

  Widget _buildDrawer() => const _AppDrawer(pantalla: 'tickets');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F7FF),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
                onMenuTap: () =>
                    _scaffoldKey.currentState?.openDrawer()),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ContadorCard(
                      label: 'Adultos',
                      precio: _precioAdulto,
                      icono: Icons.person_rounded,
                      valor: adultos,
                      onChanged: (v) => setState(() {
                        adultos = v;
                        _ticketRegistrado = false;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _ContadorCard(
                      label: 'Niños',
                      precio: _precioNino,
                      icono: Icons.child_care_rounded,
                      valor: ninos,
                      onChanged: (v) => setState(() {
                        ninos = v;
                        _ticketRegistrado = false;
                      }),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel(texto: 'Método de Pago'),
                    const SizedBox(height: 10),
                    _SelectorPago(
                      seleccionado: metodoPago,
                      onChanged: (v) => setState(() {
                        metodoPago = v;
                        _vuelto = 0;
                        _montoInsuficiente = false;
                        _montoCtrl.clear();
                      }),
                    ),
                    if (metodoPago == 'efectivo') ...[
                      const SizedBox(height: 14),
                      _EfectivoCard(
                        controller: _montoCtrl,
                        vuelto: _vuelto,
                        insuficiente: _montoInsuficiente,
                        onChanged: (_) => _calcularVuelto(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _TotalCard(adultos: adultos, ninos: ninos, total: _total),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _BotonGuardar(
              habilitado: adultos + ninos > 0,
              onTap: _irAPreview,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Widgets — Pantalla principal
// ─────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _Header({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'PISCIGRANJA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.water_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 26),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BOLETERÍA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 28),
                tooltip: 'Menú',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String texto;
  const _SectionLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D47A1),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ContadorCard extends StatelessWidget {
  final String label;
  final double precio;
  final IconData icono;
  final int valor;
  final ValueChanged<int> onChanged;
  const _ContadorCard({
    required this.label,
    required this.precio,
    required this.icono,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: const Color(0xFF1565C0), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  'S/ ${precio.toStringAsFixed(2)} c/u',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _FlechaBtn(
            icono: Icons.remove_rounded,
            habilitado: valor > 0,
            onTap: () => onChanged(valor - 1),
          ),
          SizedBox(
            width: 52,
            child: Center(
              child: Text(
                '$valor',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
          _FlechaBtn(
            icono: Icons.add_rounded,
            habilitado: true,
            onTap: () => onChanged(valor + 1),
          ),
        ],
      ),
    );
  }
}

class _FlechaBtn extends StatelessWidget {
  final IconData icono;
  final bool habilitado;
  final VoidCallback onTap;
  const _FlechaBtn(
      {required this.icono, required this.habilitado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: habilitado
              ? const Color(0xFF1565C0)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icono,
          color: habilitado ? Colors.white : Colors.grey.shade500,
          size: 20,
        ),
      ),
    );
  }
}

class _SelectorPago extends StatelessWidget {
  final String seleccionado;
  final ValueChanged<String> onChanged;
  const _SelectorPago(
      {required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChipPago(
          valor: 'efectivo',
          label: 'Efectivo',
          icono: Icons.payments_rounded,
          seleccionado: seleccionado,
          onTap: () => onChanged('efectivo'),
        ),
        const SizedBox(width: 10),
        _ChipPago(
          valor: 'yape',
          label: 'Yape',
          icono: Icons.phone_android_rounded,
          seleccionado: seleccionado,
          onTap: () => onChanged('yape'),
        ),
        const SizedBox(width: 10),
        _ChipPago(
          valor: 'plin',
          label: 'Plin',
          icono: Icons.mobile_friendly_rounded,
          seleccionado: seleccionado,
          onTap: () => onChanged('plin'),
        ),
      ],
    );
  }
}

class _ChipPago extends StatelessWidget {
  final String valor, label, seleccionado;
  final IconData icono;
  final VoidCallback onTap;
  const _ChipPago({
    required this.valor,
    required this.label,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = seleccionado == valor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF1565C0) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activo
                  ? const Color(0xFF1565C0)
                  : const Color(0xFFBBDEFB),
              width: 2,
            ),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF1565C0).withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icono,
                  color: activo ? Colors.white : const Color(0xFF1565C0),
                  size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: activo ? Colors.white : const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EfectivoCard extends StatelessWidget {
  final TextEditingController controller;
  final double vuelto;
  final bool insuficiente;
  final ValueChanged<String> onChanged;
  const _EfectivoCard({
    required this.controller,
    required this.vuelto,
    required this.insuficiente,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pago en Efectivo',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            decoration: InputDecoration(
              labelText: 'Monto entregado (S/)',
              prefixIcon: const Icon(Icons.attach_money_rounded,
                  color: Color(0xFF1565C0)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF1565C0), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
            onChanged: onChanged,
          ),
          if (vuelto > 0) ...[
            const SizedBox(height: 10),
            _InfoBox(
              color: const Color(0xFFE8F5E9),
              border: const Color(0xFF43A047),
              icono: Icons.change_circle_rounded,
              iconoColor: const Color(0xFF2E7D32),
              texto: 'Vuelto:  S/ ${vuelto.toStringAsFixed(2)}',
              textoColor: const Color(0xFF1B5E20),
            ),
          ],
          if (insuficiente) ...[
            const SizedBox(height: 10),
            _InfoBox(
              color: const Color(0xFFFFEBEE),
              border: Colors.redAccent,
              icono: Icons.warning_amber_rounded,
              iconoColor: Colors.red,
              texto:
                  'Monto insuficiente  (faltan S/ ${(-vuelto).toStringAsFixed(2)})',
              textoColor: Colors.red.shade700,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color, border, iconoColor, textoColor;
  final IconData icono;
  final String texto;
  const _InfoBox({
    required this.color,
    required this.border,
    required this.icono,
    required this.iconoColor,
    required this.texto,
    required this.textoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icono, color: iconoColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: textoColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int adultos, ninos;
  final double total;
  const _TotalCard(
      {required this.adultos, required this.ninos, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${adultos + ninos} persona(s)',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '— Adultos: $adultos',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '— Niños: $ninos',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL A PAGAR',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      letterSpacing: 1)),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonGuardar extends StatelessWidget {
  final bool habilitado;
  final VoidCallback onTap;
  const _BotonGuardar(
      {required this.habilitado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: habilitado ? onTap : null,
        icon: const Icon(Icons.save_alt_rounded, size: 22),
        label: const Text(
          'GUARDAR Y VER TICKET',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════╗
//  PANTALLA VISTA PREVIA DEL TICKET
// ╚══════════════════════════════════════╝
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

  String get _labelPago {
    switch (metodoPago) {
      case 'yape': return 'Yape';
      case 'plin': return 'Plin';
      default: return 'Efectivo';
    }
  }

  String get _fecha {
    final n = DateTime.now();
    final d = n.day.toString().padLeft(2, '0');
    final m = n.month.toString().padLeft(2, '0');
    return '$d/$m/${n.year}';
  }

  String get _hora {
    final n = DateTime.now();
    final h = n.hour.toString().padLeft(2, '0');
    final mi = n.minute.toString().padLeft(2, '0');
    return '$h:$mi';
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
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
            80 * mmPt, double.infinity, marginAll: 8 * mmPt),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Cabecera ──────────────────────────────
              pw.Text('TICKET EXPRESS',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Est. 2024',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              // ── Info ──────────────────────────────────
              pdfRow('TIPO:', 'Nueva Entrada'),
              pw.SizedBox(height: 3),
              pdfRow('FECHA:', _fecha),
              pw.SizedBox(height: 3),
              pdfRow('HORA:', _hora),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              // ── Items ─────────────────────────────────
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
              // ── Subtotal ──────────────────────────────
              pdfRow('Subtotal:', 'S/ ${total.toStringAsFixed(2)}'),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 4),
              // ── Total ─────────────────────────────────
              pdfRow('TOTAL:', 'S/ ${total.toStringAsFixed(2)}',
                  bold: true, fontSize: 16),
              // ── Pago efectivo ─────────────────────────
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
              // ── Footer ────────────────────────────────
              pw.Text('¡Gracias por su compra!',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabecera ──────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
              ),
              padding:
                  const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: TextButton.icon(
                      onPressed: () {
                        onSalir();
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      },
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 18),
                      label: const Text('Salir',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
            ),
            // ── Ticket visual ──────────────
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
                            color:
                                Colors.black.withValues(alpha: 0.13),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // ── Cabecera ──────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 22, 20, 6),
                          child: Column(
                            children: [
                              const Text(
                                'TICKET EXPRESS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: 1),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Est. 2024',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                            thickness: 1,
                            indent: 16,
                            endIndent: 16),
                        // ── Info ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 10, 20, 10),
                          child: Column(
                            children: [
                              _TicketRow(
                                  label: 'TIPO:',
                                  value: 'Nueva Entrada'),
                              const SizedBox(height: 6),
                              _TicketRow(
                                  label: 'FECHA:',
                                  value: _fecha),
                              const SizedBox(height: 6),
                              _TicketRow(
                                  label: 'HORA:',
                                  value: _hora),
                            ],
                          ),
                        ),
                        const Divider(
                            thickness: 1,
                            indent: 16,
                            endIndent: 16),
                        // ── Items ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 10, 20, 10),
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
                        const Divider(
                            thickness: 1,
                            indent: 16,
                            endIndent: 16),
                        // ── Subtotal ──────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 10, 20, 10),
                          child: _TicketRow(
                            label: 'Subtotal:',
                            value:
                                'S/ ${total.toStringAsFixed(2)}',
                          ),
                        ),
                        const Divider(
                            thickness: 2,
                            indent: 16,
                            endIndent: 16),
                        // ── Total ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 12, 20, 14),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20),
                              ),
                              Text(
                                'S/ ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                        // ── Pago efectivo ─────────────────────
                        if (metodoPago == 'efectivo') ...[
                          const Divider(
                              thickness: 1,
                              indent: 16,
                              endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 10, 20, 10),
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
                        const Divider(
                            thickness: 1,
                            indent: 16,
                            endIndent: 16),
                        // ── Footer ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          child: Text(
                            '¡Gracias por su compra!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Botones inferiores ─────────
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
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
                      icon: const Icon(Icons.print_rounded,
                          size: 22),
                      label: const Text('IMPRIMIR',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
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

// ╔══════════════════════════════════════╗
//  PANTALLA — HISTORIAL DEL DÍA
// ╚══════════════════════════════════════╝
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final registros = TicketHistorial.instance.registros;
    final total = registros.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: const _AppDrawer(pantalla: 'historial'),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ───────────────────────────────────
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: Color(0xFF1565C0)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tickets Emitidos Hoy',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF0D1B2A)),
                        ),
                        Text(
                          'Resumen de operaciones recientes',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF90B4F9), width: 1.5),
                    ),
                    child: Text(
                      '$total Total',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B6FD4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_rounded,
                          size: 20, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // ── Tabla ─────────────────────────────────────
            if (registros.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No hay tickets emitidos hoy',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Cabecera de tabla
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Row(
                        children: [
                          _ThCell(text: 'ID TICKET', flex: 3),
                          _ThCell(text: 'DETALLE', flex: 3),
                          _ThCell(
                              text: 'MONTO',
                              flex: 2,
                              right: true),
                          _ThCell(
                              text: 'HORA',
                              flex: 2,
                              right: true),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // Filas
                    Expanded(
                      child: ListView.separated(
                        itemCount: registros.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 18,
                            endIndent: 18),
                        itemBuilder: (context, i) {
                          final r = registros[i];
                          final bgColor = i.isEven
                              ? Colors.white
                              : const Color(0xFFFAFBFF);
                          final h = r.hora.hour
                              .toString()
                              .padLeft(2, '0');
                          final m = r.hora.minute
                              .toString()
                              .padLeft(2, '0');
                          return Container(
                            color: bgColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '#TK-${r.id}',
                                    style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${r.adultos} Ad. / ${r.ninos} Niñ.',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${r.monto.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF0D1B2A)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$h:$m',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

class _ThCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool right;
  const _ThCell(
      {required this.text, required this.flex, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ╔══════════════════════════════════════╗
//  PANTALLA — CONFIGURACIÓN
// ╚══════════════════════════════════════╝
class ConfiguracionScreen extends StatefulWidget {
  final int paginaInicial;
  const ConfiguracionScreen({super.key, this.paginaInicial = 0});
  @override
  State<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late TextEditingController _semanaCtrl;
  late TextEditingController _findeCtrl;
  late TextEditingController _ninoSemanaCtrl;
  late TextEditingController _ninoFindeCtrl;
  late TextEditingController _impresoraCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.paginaInicial);
    _semanaCtrl = TextEditingController(
        text: AppConfig.instance.precioAdultoSemana.toStringAsFixed(2));
    _findeCtrl = TextEditingController(
        text: AppConfig.instance.precioAdultoFinde.toStringAsFixed(2));
    _ninoSemanaCtrl = TextEditingController(
        text: AppConfig.instance.precioNinoSemana.toStringAsFixed(2));
    _ninoFindeCtrl = TextEditingController(
        text: AppConfig.instance.precioNinoFinde.toStringAsFixed(2));
    _impresoraCtrl =
        TextEditingController(text: AppConfig.instance.nombreImpresora);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _semanaCtrl.dispose();
    _findeCtrl.dispose();
    _ninoSemanaCtrl.dispose();
    _ninoFindeCtrl.dispose();
    _impresoraCtrl.dispose();
    super.dispose();
  }

  void _guardarPrecios() {
    final adultoSemana = double.tryParse(_semanaCtrl.text);
    final adultoFinde = double.tryParse(_findeCtrl.text);
    final ninoSemana = double.tryParse(_ninoSemanaCtrl.text);
    final ninoFinde = double.tryParse(_ninoFindeCtrl.text);
    if (adultoSemana == null || adultoFinde == null ||
        ninoSemana == null || ninoFinde == null ||
        adultoSemana <= 0 || adultoFinde <= 0 ||
        ninoSemana <= 0 || ninoFinde <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa precios válidos (todos > 0)')));
      return;
    }
    AppConfig.instance.actualizarPrecios(
      adultoSemana: adultoSemana,
      adultoFinde: adultoFinde,
      ninoSemana: ninoSemana,
      ninoFinde: ninoFinde,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Precios guardados'),
        backgroundColor: Color(0xFF1565C0)));
  }

  void _guardarImpresora() {
    AppConfig.instance.nombreImpresora = _impresoraCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impresora guardada'),
        backgroundColor: Color(0xFF1565C0)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: const _AppDrawer(pantalla: 'config'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Configuración',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menú',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.sell_rounded), text: 'Precios'),
            Tab(icon: Icon(Icons.print_rounded), text: 'Impresora'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab Precios ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dos columnas lado a lado ──────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Columna: Días de semana ──
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.work_rounded,
                                    color: Color(0xFF1565C0), size: 18),
                                const SizedBox(width: 6),
                                const Text('Lun – Vie',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF0D47A1))),
                              ]),
                              const SizedBox(height: 14),
                              // Adulto
                              Row(children: [
                                const Icon(Icons.person_rounded,
                                    color: Color(0xFF1565C0), size: 16),
                                const SizedBox(width: 4),
                                const Text('Adulto',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D47A1))),
                              ]),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _semanaCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'))
                                ],
                                decoration: const InputDecoration(
                                  prefixText: 'S/ ',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF1565C0), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Niño
                              Row(children: [
                                const Icon(Icons.child_care_rounded,
                                    color: Color(0xFF1565C0), size: 16),
                                const SizedBox(width: 4),
                                const Text('Niño',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D47A1))),
                              ]),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _ninoSemanaCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'))
                                ],
                                decoration: const InputDecoration(
                                  prefixText: 'S/ ',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF1565C0), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // ── Columna: Fin de semana ───
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.wb_sunny_rounded,
                                    color: Color(0xFFE65100), size: 18),
                                const SizedBox(width: 6),
                                const Text('Sáb – Dom',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFFE65100))),
                              ]),
                              const SizedBox(height: 14),
                              // Adulto
                              Row(children: [
                                const Icon(Icons.person_rounded,
                                    color: Color(0xFFE65100), size: 16),
                                const SizedBox(width: 4),
                                const Text('Adulto',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE65100))),
                              ]),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _findeCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'))
                                ],
                                decoration: const InputDecoration(
                                  prefixText: 'S/ ',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFFE65100), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Niño
                              Row(children: [
                                const Icon(Icons.child_care_rounded,
                                    color: Color(0xFFE65100), size: 16),
                                const SizedBox(width: 4),
                                const Text('Niño',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE65100))),
                              ]),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _ninoFindeCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'))
                                ],
                                decoration: const InputDecoration(
                                  prefixText: 'S/ ',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFFE65100), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _guardarPrecios,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('GUARDAR PRECIOS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // ── Tab Impresora ────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                _ConfigCard(
                  titulo: 'Nombre de la impresora',
                  descripcion:
                      'Ingresa el nombre exacto del dispositivo',
                  icono: Icons.print_rounded,
                  child: TextField(
                    controller: _impresoraCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: POS-80C, EPSON TM-T20',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0xFF1565C0), width: 2),
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
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0D47A1))),
            ],
          ),
          const SizedBox(height: 2),
          Text(descripcion,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Widgets — Pantalla preview
// ─────────────────────────────────────────

class _TicketRow extends StatelessWidget {
  final String label, value;
  const _TicketRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ╔══════════════════════════════════════╗
//  WIDGET COMPARTIDO — CAJÓN DE NAVEGACIÓN
// ╚══════════════════════════════════════╝
class _AppDrawer extends StatelessWidget {
  /// 'tickets' | 'historial' | 'config'
  final String pantalla;
  const _AppDrawer({required this.pantalla});

  void _ir(BuildContext context, String destino, {int tab = 0}) {
    final nav = Navigator.of(context);
    nav.pop(); // cierra el drawer
    switch (destino) {
      case 'tickets':
        nav.popUntil((r) => r.isFirst);
      case 'historial':
        if (pantalla == 'historial') return;
        if (pantalla != 'tickets') nav.popUntil((r) => r.isFirst);
        nav.push(MaterialPageRoute(
            builder: (_) => const HistorialScreen()));
      case 'config':
        if (pantalla == 'config') return;
        if (pantalla != 'tickets') nav.popUntil((r) => r.isFirst);
        nav.push(MaterialPageRoute(
            builder: (_) =>
                ConfiguracionScreen(paginaInicial: tab)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1565C0);
    const activeBg = Color(0xFFE8F0FE);

    Widget item({
      required String clave,
      required IconData icono,
      required String titulo,
      required String subtitulo,
      VoidCallback? onTap,
    }) {
      final activo = pantalla == clave;
      return ListTile(
        selected: activo,
        selectedTileColor: activeBg,
        leading: Icon(icono, color: activeColor),
        title: Text(titulo,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: activo ? activeColor : null)),
        subtitle: Text(subtitulo),
        onTap: onTap,
      );
    }

    return Drawer(
      child: Column(
        children: [
          // ── Cabecera ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.water_rounded,
                    color: Colors.white70, size: 36),
                SizedBox(height: 10),
                Text('PISCIGRANJA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                Text('Boletería',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Tickets ───────────────────────────────
          item(
            clave: 'tickets',
            icono: Icons.confirmation_number_rounded,
            titulo: 'Tickets',
            subtitulo: 'Emitir nuevos tickets',
            onTap: () => _ir(context, 'tickets'),
          ),
          // ── Historial ─────────────────────────────
          item(
            clave: 'historial',
            icono: Icons.history_rounded,
            titulo: 'Historial del Día',
            subtitulo: 'Ver tickets emitidos hoy',
            onTap: () => _ir(context, 'historial'),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('CONFIGURACIÓN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2)),
          ),
          // ── Precio del ticket ─────────────────────
          ListTile(
            selected: pantalla == 'config',
            selectedTileColor: activeBg,
            leading:
                const Icon(Icons.sell_rounded, color: activeColor),
            title: const Text('Precio del Ticket',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
                'Adulto S/ ${AppConfig.instance.precioAdultoSemana.toStringAsFixed(2)}'  
                '  ·  Finde S/ ${AppConfig.instance.precioAdultoFinde.toStringAsFixed(2)}'),
            onTap: () => _ir(context, 'config', tab: 0),
          ),
          // ── Impresora ─────────────────────────────
          ListTile(
            leading:
                const Icon(Icons.print_rounded, color: activeColor),
            title: const Text('Impresora',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(AppConfig.instance.nombreImpresora.isEmpty
                ? 'No configurada'
                : AppConfig.instance.nombreImpresora),
            onTap: () => _ir(context, 'config', tab: 1),
          ),
        ],
      ),
    );
  }
}


