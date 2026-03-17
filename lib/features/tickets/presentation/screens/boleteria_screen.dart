import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _montoInsuficiente = false;
  bool _ticketRegistrado = false;

  bool get _esFinde => DateTime.now().weekday >= 6;

  double _precioAdulto(ConfigProvider cfg) =>
      _esFinde ? cfg.precioAdultoFinde : cfg.precioAdultoSemana;

  double _precioNino(ConfigProvider cfg) =>
      _esFinde ? cfg.precioNinoFinde : cfg.precioNinoSemana;

  double _total(ConfigProvider cfg) =>
      adultos * _precioAdulto(cfg) + ninos * _precioNino(cfg);

  void _calcularVuelto(ConfigProvider cfg) {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    setState(() {
      _vuelto = monto - _total(cfg);
      _montoInsuficiente = monto > 0 && _vuelto < 0;
    });
  }

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
      _montoInsuficiente = false;
      _ticketRegistrado = false;
    });
  }

  Future<void> _irAPreview(ConfigProvider cfg) async {
    if (adultos + ninos == 0) return;
    if (!_ticketRegistrado) {
      await context.read<TicketProvider>().agregarTicket(
            adultos: adultos,
            ninos: ninos,
            monto: _total(cfg),
            metodoPago: metodoPago,
          );
      _ticketRegistrado = true;
    }
    if (!mounted) return;
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ContadorCard(
                      label: 'Adultos',
                      precio: precioAdulto,
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
                      precio: precioNino,
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
                        onChanged: (_) => _calcularVuelto(cfg),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _TotalCard(adultos: adultos, ninos: ninos, total: total),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _BotonGuardar(
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
                  const Text('PISCIGRANJA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                  const SizedBox(width: 8),
                  Icon(Icons.water_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 26),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('BOLETERÍA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5)),
              ),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 28),
                tooltip: 'Volver',
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
          letterSpacing: 0.5),
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
              offset: const Offset(0, 4))
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E))),
                Text('S/ ${precio.toStringAsFixed(2)} c/u',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _FlechaBtn(
              icono: Icons.remove_rounded,
              habilitado: valor > 0,
              onTap: () => onChanged(valor - 1)),
          SizedBox(
            width: 52,
            child: Center(
              child: Text('$valor',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: habilitado ? const Color(0xFF1565C0) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono,
            color: habilitado ? Colors.white : Colors.grey.shade500, size: 20),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF1565C0) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  activo ? const Color(0xFF1565C0) : const Color(0xFFBBDEFB),
              width: 2,
            ),
            boxShadow: activo
                ? [
                    BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icono,
                  color: activo ? Colors.white : const Color(0xFF1565C0),
                  size: 22),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          activo ? Colors.white : const Color(0xFF1565C0))),
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pago en Efectivo',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                  fontSize: 14)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Text(texto,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textoColor)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${adultos + ninos} persona(s)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text('— Adultos: $adultos',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text('— Niños: $ninos',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
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
              Text('S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
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
  const _BotonGuardar({required this.habilitado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: habilitado ? onTap : null,
        icon: const Icon(Icons.save_alt_rounded, size: 22),
        label: const Text('GUARDAR Y VER TICKET',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
