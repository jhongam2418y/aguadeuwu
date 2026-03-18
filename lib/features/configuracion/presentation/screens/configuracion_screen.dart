import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../../data/models/config_model.dart';

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
        length: 2, vsync: this, initialIndex: widget.paginaInicial);
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
    for (final c in _adultoCtrls) c.dispose();
    for (final c in _ninoCtrls) c.dispose();
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // â”€â”€ Tab Precios â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                child: ElevatedButton.icon(
                  onPressed: _guardarPrecios,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('GUARDAR PRECIOS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          // â”€â”€ Tab Impresora â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        ],
      ),
    );
  }
}

// â”€â”€â”€ Tarjeta por día â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          // â”€â”€ Cabecera del día â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

