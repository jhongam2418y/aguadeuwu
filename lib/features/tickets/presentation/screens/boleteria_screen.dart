import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_preview_screen.dart';

class BoleteriaScreen extends StatefulWidget {
  const BoleteriaScreen({super.key});
  @override
  State<BoleteriaScreen> createState() => _BoleteriaScreenState();
}

class _BoleteriaScreenState extends State<BoleteriaScreen> {
  int adultos = 0;
  int ninos = 0;
  String metodoPago = 'efectivo';
  final TextEditingController _montoCtrl = TextEditingController();
  double _vuelto = 0;

  double _precioAdulto(ConfigProvider cfg) =>
      cfg.precioAdulto(DateTime.now().weekday);

  double _precioNino(ConfigProvider cfg) =>
      cfg.precioNino(DateTime.now().weekday);

  double _total(ConfigProvider cfg) =>
      adultos * _precioAdulto(cfg) + ninos * _precioNino(cfg);

  @override
  void dispose() {
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
    });
  }

  Future<void> _irAPreview(ConfigProvider cfg) async {
    if (adultos + ninos == 0) return;
    if (!mounted) return;
    final provider = context.read<TicketProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPreviewScreen(
          adultos: adultos,
          ninos: ninos,
          precioAdulto: _precioAdulto(cfg),
          precioNino: _precioNino(cfg),
          total: _total(cfg),
          metodoPago: metodoPago,
          montoEntregado: double.tryParse(_montoCtrl.text) ?? 0,
          vuelto: _vuelto,
          onSalir: _resetear,
          onGuardar: () => provider.agregarTicket(
            adultos: adultos,
            ninos: ninos,
            monto: _total(cfg),
            metodoPago: metodoPago,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ConfigProvider>();
    final precioAdulto = _precioAdulto(cfg);
    final precioNino = _precioNino(cfg);
    final total = _total(cfg);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBackTap: () => Navigator.pop(context)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Panel izquierdo: selectores ──────────────────────────
                  Expanded(
                    flex: 3,
                    child: Padding(
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
                              onChanged: (v) => setState(() => adultos = v),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _ContadorCard(
                              label: 'Niños',
                              precio: precioNino,
                              icono: Icons.child_care_rounded,
                              valor: ninos,
                              onChanged: (v) => setState(() => ninos = v),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _SectionLabel(texto: 'MÉTODO DE PAGO'),
                          const SizedBox(height: 10),
                          _SelectorPago(
                            seleccionado: metodoPago,
                            onChanged: (v) => setState(() {
                              metodoPago = v;
                              _vuelto = 0;
                              _montoCtrl.clear();
                            }),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  // ── Divisor ──────────────────────────────────────────────
                  Container(
                    width: 1,
                    color: const Color(0xFFCCE0FF),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // ── Panel derecho: vista previa ──────────────────────────
                  Expanded(
                    flex: 2,
                    child: Padding(
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
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              adultos: adultos,
              ninos: ninos,
              total: total,
              habilitado: adultos + ninos > 0,
              onTap: () => _irAPreview(cfg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBackTap;
  const _Header({required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF003D99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
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
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PISCIGRANJA',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0052CC).withValues(alpha: 0.09),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0052CC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: const Color(0xFF0052CC), size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0052CC))),
                const SizedBox(height: 4),
                Text('S/ ${precio.toStringAsFixed(2)} c/u',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0052CC),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _FlechaBtn(
              icono: Icons.remove_rounded,
              habilitado: valor > 0,
              onTap: () => onChanged(valor - 1)),
          SizedBox(
            width: 72,
            child: Center(
              child: Text('$valor',
                  style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0052CC))),
            ),
          ),
          _FlechaBtn(
              icono: Icons.add_rounded,
              habilitado: true,
              onTap: () => onChanged(valor + 1)),
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
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habilitado ? const Color(0xFF0052CC) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: habilitado
              ? [
                  BoxShadow(
                      color: const Color(0xFF0052CC).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Icon(icono,
            color: habilitado ? Colors.white : Colors.grey.shade400, size: 28),
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
            onTap: () => onChanged('efectivo')),
        const SizedBox(width: 10),
        _ChipPago(
            valor: 'yape',
            label: 'Yape',
            icono: Icons.phone_android_rounded,
            seleccionado: seleccionado,
            onTap: () => onChanged('yape')),
        const SizedBox(width: 10),
        _ChipPago(
            valor: 'plin',
            label: 'Plin',
            icono: Icons.mobile_friendly_rounded,
            seleccionado: seleccionado,
            onTap: () => onChanged('plin')),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF0052CC) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  activo ? const Color(0xFF0052CC) : const Color(0xFFCCE0FF),
              width: 2,
            ),
            boxShadow: activo
                ? [
                    BoxShadow(
                        color: const Color(0xFF0052CC).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icono,
                  color: activo ? Colors.white : const Color(0xFF0052CC),
                  size: 22),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          activo ? Colors.white : const Color(0xFF0052CC))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int adultos, ninos;
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
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
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
                        color: Color(0xFF0052CC))),
                Text('Adultos: $adultos   Niños: $ninos',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
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
                        color: Color(0xFF0052CC))),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: habilitado ? onTap : null,
            icon: const Icon(Icons.print_rounded, size: 24),
            label: const Text('IMPRIMIR TICKET',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
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

class _TicketPreviewCard extends StatelessWidget {
  final int adultos, ninos;
  final double precioAdulto, precioNino, total;
  final String metodoPago;

  const _TicketPreviewCard({
    required this.adultos,
    required this.ninos,
    required this.precioAdulto,
    required this.precioNino,
    required this.total,
    required this.metodoPago,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour;
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${h12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052CC).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabecera azul
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0052CC),
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
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0052CC))),
                Text('S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFF0052CC))),
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
                Text('PAGO: ${metodoPago.toUpperCase()}',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text('FECHA: $fecha',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          // QR placeholder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
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
                      color: const [
                            true,  false, true,  true,
                            false, true,  false, true,
                            true,  false, true,  false,
                            true,  true,  false, true,
                          ][i]
                          ? Colors.grey.shade400
                          : Colors.transparent,
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
                    color: Color(0xFF0052CC))),
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
