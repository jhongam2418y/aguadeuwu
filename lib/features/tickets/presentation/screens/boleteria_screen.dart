import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_preview_screen.dart';
import '../../../../core/app_colors.dart';

// =============================================================================
// BoleteriaScreen
// =============================================================================
class BoleteriaScreen extends StatefulWidget {
  const BoleteriaScreen({super.key});

  @override
  State<BoleteriaScreen> createState() => _BoleteriaScreenState();
}

class _BoleteriaScreenState extends State<BoleteriaScreen> {
  int _adultos = 0;
  int _ninos = 0;
  final _metodos = <String>['efectivo'];
  // monto asignado al primer método cuando hay pago dividido
  double _montoPrincipal = 0.0;

  String _buildMetodoSnap(double total) {
    if (_metodos.length == 2) {
      final m1 = _montoPrincipal.clamp(0.0, total);
      final m2 = (total - m1).clamp(0.0, total);
      return '${_metodos[0]}:${m1.toStringAsFixed(2)}'
             '+${_metodos[1]}:${m2.toStringAsFixed(2)}';
    }
    return _metodos.join('+');
  }

  void _toggleMetodo(String valor, double total) {
    setState(() {
      final idx = _metodos.indexOf(valor);
      if (idx >= 0) {
        if (_metodos.length > 1) {
          _metodos.removeAt(idx);
          _montoPrincipal = 0.0;
        }
      } else if (_metodos.length < 2) {
        _metodos.add(valor);
        _montoPrincipal = total; // principal lleva todo por defecto
      }
    });
  }

  // ── Helpers de precio (sin lógica de UI, solo cálculos) ──────────────────

  double _precioAdulto(ConfigProvider cfg) =>
      cfg.precioAdulto(DateTime.now().weekday);

  double _precioNino(ConfigProvider cfg) =>
      cfg.precioNino(DateTime.now().weekday);

  double _calcTotal(ConfigProvider cfg) =>
      _adultos * _precioAdulto(cfg) + _ninos * _precioNino(cfg);

  void _resetear() => setState(() {
        _adultos = 0;
        _ninos = 0;
        _montoPrincipal = 0.0;
        _metodos
          ..clear()
          ..add('efectivo');
      });

  // ── Navegación a preview ──────────────────────────────────────────────────

  Future<void> _irAPreview(ConfigProvider cfg) async {
    if (_adultos + _ninos == 0 || !mounted) return;

    final provider = context.read<TicketProvider>();
    final precioAdulto = _precioAdulto(cfg);
    final precioNino = _precioNino(cfg);
    final total = _calcTotal(cfg);

    // Capturamos los valores actuales antes de navegar para evitar
    // que un rebuild los mute mientras la pantalla está abierta.
    final adultoSnap = _adultos;
    final ninoSnap = _ninos;
    final metodoSnap = _buildMetodoSnap(total);

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPreviewScreen(
          adultos: adultoSnap,
          ninos: ninoSnap,
          precioAdulto: precioAdulto,
          precioNino: precioNino,
          total: total,
          metodoPago: metodoSnap,
          onSalir: _resetear,
          onGuardar: () async {
            final ticket = await provider.agregarTicket(
              adultos: adultoSnap,
              ninos: ninoSnap,
              monto: total,
              metodoPago: metodoSnap,
            );
            if (!mounted) return -1;
            Navigator.pop(context);
            _resetear();
            return ticket.id;
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Selector selectivo: solo reconstruye cuando cambian precios
    final cfg = context.watch<ConfigProvider>();
    final precioAdulto = _precioAdulto(cfg);
    final precioNino = _precioNino(cfg);
    final total = _calcTotal(cfg);
    final habilitado = _adultos + _ninos > 0;

    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Panel izquierdo
                  Expanded(
                    flex: 3,
                    child: _LeftPanel(
                      adultos: _adultos,
                      ninos: _ninos,
                      precioAdulto: precioAdulto,
                      precioNino: precioNino,
                      total: total,
                      metodos: _metodos,
                      montoPrincipal: _montoPrincipal,
                      onAdultosChanged: (v) => setState(() => _adultos = v),
                      onNinosChanged: (v) => setState(() => _ninos = v),
                      onToggleMetodo: (v) => _toggleMetodo(v, total),
                      onMontoPrincipalChanged: (v) =>
                          setState(() => _montoPrincipal = v),
                    ),
                  ),
                  // Divisor
                  const _VerticalDivider(),
                  // Panel derecho
                  Expanded(
                    flex: 2,
                    child: _RightPanel(
                      adultos: _adultos,
                      ninos: _ninos,
                      precioAdulto: precioAdulto,
                      precioNino: precioNino,
                      total: total,
                      metodoPago: _buildMetodoSnap(total),
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              adultos: _adultos,
              ninos: _ninos,
              total: total,
              habilitado: habilitado,
              onTap: () => _irAPreview(cfg),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Paneles principales (evitan rebuilds innecesarios siendo StatelessWidget)
// =============================================================================

class _LeftPanel extends StatelessWidget {
  final int adultos;
  final int ninos;
  final double precioAdulto;
  final double precioNino;
  final double total;
  final List<String> metodos;
  final double montoPrincipal;
  final ValueChanged<int> onAdultosChanged;
  final ValueChanged<int> onNinosChanged;
  final ValueChanged<String> onToggleMetodo;
  final ValueChanged<double> onMontoPrincipalChanged;

  const _LeftPanel({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodos,
    required this.montoPrincipal,
    required this.onAdultosChanged,
    required this.onNinosChanged,
    required this.onToggleMetodo,
    required this.onMontoPrincipalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(texto: 'SELECCIONE CANTIDAD'),
          const SizedBox(height: 10),
          Expanded(
            child: _ContadorCard(
              label: 'Adultos',
              precio: precioAdulto,
              icono: Icons.person_rounded,
              valor: adultos,
              onChanged: onAdultosChanged,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _ContadorCard(
              label: 'Niños',
              precio: precioNino,
              icono: Icons.child_care_rounded,
              valor: ninos,
              onChanged: onNinosChanged,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(texto: 'MÉTODO DE PAGO'),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: _SelectorPago(
              metodos: metodos,
              onToggle: onToggleMetodo,
            ),
          ),
          if (metodos.length == 2) ...[            const SizedBox(height: 10),
            _SplitPagoPanel(
              metodos: metodos,
              montoPrincipal: montoPrincipal,
              total: total,
              onMontoPrincipalChanged: onMontoPrincipalChanged,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final int adultos;
  final int ninos;
  final double precioAdulto;
  final double precioNino;
  final double total;
  final String metodoPago;

  const _RightPanel({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodoPago,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(texto: 'VISTA PREVIA DEL TICKET'),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _TicketPreviewCard(
                adultos: adultos,
                ninos: ninos,
                precioAdulto: precioAdulto,
                precioNino: precioNino,
                total: total,
                metodoPago: metodoPago,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets de UI
// =============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 28),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NUEVO TICKET',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                Text('Emisión de comprobante de ingreso',
                    style:
                        TextStyle(color: AppColors.lightBlueBackground, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PISCIGRANJA',
                  style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 11,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(0x18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('BOLETERÍA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Divisor vertical entre paneles
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: const Color(0xFFB2DFDB),
      margin: const EdgeInsets.symmetric(vertical: 16),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey,
          letterSpacing: 1.2),
    );
  }
}

// =============================================================================
// _ContadorCard
// =============================================================================
class _ContadorCard extends StatelessWidget {
  final String label;
  final double precio;
  final IconData icono;
  final int valor;
  final ValueChanged<int> onChanged;
  static const int _max = 20;

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.blueOpacity09,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Ícono izquierdo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blueOpacity10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: AppColors.primaryBlue, size: 36),
          ),
          const SizedBox(width: 18),
          // Etiqueta y precio
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 4),
                Text('S/ ${precio.toStringAsFixed(2)} c/u',
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Controles: menos / valor / más
          _FlechaBtn(
            icono: Icons.remove_rounded,
            habilitado: valor > 0,
            onTap: () => onChanged(valor - 1),
          ),
          SizedBox(
            width: 72,
            child: Center(
              child: Text('$valor',
                  style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue)),
            ),
          ),
          _FlechaBtn(
            icono: Icons.add_rounded,
            habilitado: valor < _max,
            onTap: () => onChanged(valor + 1),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _FlechaBtn
// =============================================================================
class _FlechaBtn extends StatelessWidget {
  final IconData icono;
  final bool habilitado;
  final VoidCallback onTap;

  const _FlechaBtn({
    required this.icono,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habilitado ? AppColors.primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: habilitado
              ? [
                  BoxShadow(
                      color: AppColors.blueOpacity35,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : const [],
        ),
        child: Icon(
          icono,
          color: habilitado ? Colors.white : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}

// =============================================================================
// _SelectorPago
// =============================================================================

// Datos de cada método de pago centralizados para no repetir strings sueltos
class _MetodoPagoData {
  final String valor;
  final String label;
  final IconData icono;
  final String? imagePath;
  const _MetodoPagoData(this.valor, this.label, this.icono, {this.imagePath});
}

const _metodosPago = [
  _MetodoPagoData('efectivo', 'Efectivo', Icons.payments_rounded),
  _MetodoPagoData('yape', 'Yape', Icons.phone_android_rounded, imagePath: 'assets/images/yape.png'),
  _MetodoPagoData('plin', 'Plin', Icons.mobile_friendly_rounded, imagePath: 'assets/images/plin.png'),
];

class _SelectorPago extends StatelessWidget {
  final List<String> metodos;
  final ValueChanged<String> onToggle;

  const _SelectorPago({
    required this.metodos,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final lleno = metodos.length >= 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _metodosPago.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _ChipPago(
            data: _metodosPago[i],
            orden: metodos.indexOf(_metodosPago[i].valor),
            bloqueado: lleno && !metodos.contains(_metodosPago[i].valor),
            onTap: () => onToggle(_metodosPago[i].valor),
          ),
        ],
      ],
    );
  }
}

class _ChipPago extends StatelessWidget {
  /// orden: -1 = inactivo · 0 = principal · 1 = adicional
  final _MetodoPagoData data;
  final int orden;
  final bool bloqueado;
  final VoidCallback onTap;

  const _ChipPago({
    required this.data,
    required this.orden,
    required this.bloqueado,
    required this.onTap,
  });

  static const _azul         = AppColors.primaryBlue;
  static const _naranja      = Color(0xFFFF8F00);
  static const _fondoNaranja = Color(0xFFFFF3E0);
  static const _bordeVerde   = Color(0xFFB2DFDB);

  @override
  Widget build(BuildContext context) {
    final esPrimario  = orden == 0;
    final esAdicional = orden == 1;
    final activo      = esPrimario || esAdicional;

    final chipColor   = esPrimario  ? _azul
                      : esAdicional ? _fondoNaranja
                      : bloqueado   ? const Color(0xFFF5F5F5)
                      : Colors.white;
    final borderColor = esPrimario  ? _azul
                      : esAdicional ? _naranja
                      : bloqueado   ? Colors.grey.shade300
                      : _bordeVerde;
    final iconColor   = esPrimario  ? Colors.white
                      : esAdicional ? _naranja
                      : bloqueado   ? Colors.grey.shade400
                      : _azul;
    final badgeColor  = esPrimario  ? _azul : _naranja;
    final hint        = esPrimario  ? 'Principal'
                      : esAdicional ? 'Adicional'
                      : bloqueado   ? 'Quita uno'
                      :               'Agregar';

    return Expanded(
      child: GestureDetector(
        onTap: bloqueado ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: esPrimario
                ? [BoxShadow(
                    color: AppColors.blueOpacity28,
                    blurRadius: 8,
                    offset: const Offset(0, 4))]
                : esAdicional
                    ? [BoxShadow(
                        color: _naranja.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4))]
                    : const [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (data.imagePath != null)
                      Image.asset(data.imagePath!, height: 32)
                    else
                      Icon(data.icono, color: iconColor, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      data.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        hint,
                        key: ValueKey(hint),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: activo
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: iconColor.withValues(
                              alpha: activo ? 0.85 : 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (activo)
                Positioned(
                  top: -8,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${orden + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
// _SplitPagoPanel — inputs de monto para pago dividido
// =============================================================================
class _SplitPagoPanel extends StatefulWidget {
  final List<String> metodos;
  final double montoPrincipal;
  final double total;
  final ValueChanged<double> onMontoPrincipalChanged;

  const _SplitPagoPanel({
    required this.metodos,
    required this.montoPrincipal,
    required this.total,
    required this.onMontoPrincipalChanged,
  });

  @override
  State<_SplitPagoPanel> createState() => _SplitPagoPanelState();
}

class _SplitPagoPanelState extends State<_SplitPagoPanel> {
  late final TextEditingController _ctrl0;
  late final TextEditingController _ctrl1;
  bool _editando0 = false;

  @override
  void initState() {
    super.initState();
    _ctrl0 = TextEditingController(
        text: widget.montoPrincipal.toStringAsFixed(2));
    _ctrl1 = TextEditingController(
        text: (widget.total - widget.montoPrincipal).toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_SplitPagoPanel old) {
    super.didUpdateWidget(old);
    // Sincronizar cuando cambia el total externamente (cambio de personas)
    if (old.total != widget.total || old.metodos != widget.metodos) {
      final m1 = widget.montoPrincipal.clamp(0.0, widget.total);
      final m2 = (widget.total - m1).clamp(0.0, widget.total);
      if (!_editando0) {
        _ctrl0.text = m1.toStringAsFixed(2);
        _ctrl1.text = m2.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _ctrl0.dispose();
    _ctrl1.dispose();
    super.dispose();
  }

  String _label(String valor) {
    final found = _metodosPago.where((m) => m.valor == valor).firstOrNull;
    return found?.label ?? (valor[0].toUpperCase() + valor.substring(1));
  }

  String? _imagen(String valor) {
    final found = _metodosPago.where((m) => m.valor == valor).firstOrNull;
    return found?.imagePath;
  }

  static const _paso = 0.50;

  /// Ajusta el monto del campo 0 en [delta] (puede ser +0.50 o -0.50)
  /// y sincroniza el campo 1.
  void _ajustar(double delta) {
    final nuevo = (widget.montoPrincipal + delta).clamp(0.0, widget.total);
    // Redondear a múltiplos de 0.50 para evitar acumulación de decimales
    final redondeado = (nuevo / _paso).round() * _paso;
    final clamped = redondeado.clamp(0.0, widget.total);
    widget.onMontoPrincipalChanged(clamped);
    _ctrl0.text = clamped.toStringAsFixed(2);
    _ctrl1.text = (widget.total - clamped).toStringAsFixed(2);
  }

  void _onChanged0(String raw) {
    final v = double.tryParse(raw) ?? 0.0;
    final clamped = v.clamp(0.0, widget.total);
    widget.onMontoPrincipalChanged(clamped);
    _ctrl1.text = (widget.total - clamped).toStringAsFixed(2);
  }

  void _onChanged1(String raw) {
    final v = double.tryParse(raw) ?? 0.0;
    final clamped = v.clamp(0.0, widget.total);
    final newPrincipal = (widget.total - clamped).clamp(0.0, widget.total);
    widget.onMontoPrincipalChanged(newPrincipal);
    _ctrl0.text = newPrincipal.toStringAsFixed(2);
  }

  Widget _fieldCard(String metodoValor, TextEditingController ctrl,
      ValueChanged<String> onChanged, bool isPrimary) {
    final img = _imagen(metodoValor);
    final lbl = _label(metodoValor);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado: logo + nombre
            Row(
              children: [
                if (img != null)
                  Image.asset(img, height: 18)
                else
                  const Icon(Icons.payments_rounded,
                      size: 18, color: Color(0xFF00695C)),
                const SizedBox(width: 6),
                Text(lbl,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00695C))),
              ],
            ),
            const SizedBox(height: 8),
            // Monto + flechas (solo en el campo principal)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onTap: () => setState(() => _editando0 = isPrimary),
                    onChanged: onChanged,
                    onSubmitted: (_) => setState(() => _editando0 = false),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                      prefixText: 'S/ ',
                      prefixStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A)),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (isPrimary) ...[
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ArrowBtn(
                        icon: Icons.keyboard_arrow_up_rounded,
                        onTap: () => _ajustar(_paso),
                        enabled: widget.montoPrincipal < widget.total,
                      ),
                      const SizedBox(height: 2),
                      _ArrowBtn(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => _ajustar(-_paso),
                        enabled: widget.montoPrincipal > 0,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.metodos.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DIVIDIR PAGO',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E6D68),
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _fieldCard(widget.metodos[0], _ctrl0, _onChanged0, true),
            const SizedBox(width: 10),
            _fieldCard(widget.metodos[1], _ctrl1, _onChanged1, false),
          ],
        ),
      ],
    );
  }
}

// Botón de flecha pequeño para el split de pago
class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _ArrowBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF00695C).withValues(alpha: 0.10)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? const Color(0xFF00695C).withValues(alpha: 0.25)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 26,
          color: enabled ? const Color(0xFF00695C) : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// =============================================================================
// _BottomBar
// =============================================================================
class _BottomBar extends StatelessWidget {
  final int adultos;
  final int ninos;
  final double total;
  final bool habilitado;
  final VoidCallback onTap;

  const _BottomBar({
    required this.adultos,
    required this.ninos,
    required this.total,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          // Resumen de venta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('RESUMEN DE VENTA',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text('${adultos + ninos} persona(s)',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue)),
                Text('Adultos: $adultos   Niños: $ninos',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          // Total
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('TOTAL A PAGAR',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text('S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue)),
              ],
            ),
          ),
          // Botón imprimir
          ElevatedButton.icon(
            onPressed: habilitado ? onTap : null,
            icon: const Icon(Icons.print_rounded, size: 26),
            label: const Text('IMPRIMIR TICKET',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding:
                  const EdgeInsets.symmetric(vertical: 27, horizontal: 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _TicketPreviewCard
// =============================================================================
class _TicketPreviewCard extends StatelessWidget {
  final int adultos;
  final int ninos;
  final double precioAdulto;
  final double precioNino;
  final double total;
  final String metodoPago;

  const _TicketPreviewCard({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodoPago,
  });

  /// Formatea la fecha/hora actual en 12h sin intl para no añadir dependencia.
  String get _fechaHora {
    final n = DateTime.now();
    final h = n.hour;
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year} '
        '${h12.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.blueOpacity10,
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Cabecera
          _TicketHeader(),
          // Cabecera de tabla
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: const [
                SizedBox(
                    width: 34,
                    child: Text('CANT',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                Expanded(
                    child: Text('DETALLE',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700))),
                Text('SUBT.',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 8),
          _PreviewRow(
            cant: adultos,
            label: 'Adultos (S/ ${precioAdulto.toStringAsFixed(2)})',
            subtotal: adultos * precioAdulto,
          ),
          const SizedBox(height: 6),
          _PreviewRow(
            cant: ninos,
            label: 'Niños (S/ ${precioNino.toStringAsFixed(2)})',
            subtotal: ninos * precioNino,
          ),
          const SizedBox(height: 10),
          const Divider(indent: 14, endIndent: 14, thickness: 1.5),
          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.primaryBlue)),
                Text('S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primaryBlue)),
              ],
            ),
          ),
          // Pie: pago y fecha
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFFF8F9FA),
            child: Column(
              children: [
                Text(
                  'PAGO: ${metodoPago.split('+').map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join(' + ')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text('FECHA: $_fechaHora',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          // QR decorativo
          const Padding(
            padding: EdgeInsets.all(14),
            child: _QrPlaceholder(),
          ),
        ],
      ),
    );
  }
}

// Cabecera azul del ticket preview (extraída para no reconstruirla)
class _TicketHeader extends StatelessWidget {
  const _TicketHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Column(
        children: [
          Text('PISCIGRANJA',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 2)),
          SizedBox(height: 3),
          Text('TICKET DE INGRESO',
              style: TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 10,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

// QR decorativo extraído para ser const y no reconstruirse nunca
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  static const _pattern = [
    true,  false, true,  true,
    false, true,  false, true,
    true,  false, true,  false,
    true,  true,  false, true,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 52,
        height: 52,
        child: GridView.count(
          crossAxisCount: 4,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            16,
            (i) => Container(
              margin: const EdgeInsets.all(1.5),
              color: _pattern[i] ? Colors.grey.shade400 : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _PreviewRow
// =============================================================================
class _PreviewRow extends StatelessWidget {
  final int cant;
  final String label;
  final double subtotal;

  const _PreviewRow({
    required this.cant,
    required this.label,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('$cant',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF424242))),
          ),
          Text('S/ ${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}