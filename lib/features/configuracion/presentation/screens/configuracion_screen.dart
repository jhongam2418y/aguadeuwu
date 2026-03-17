import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../../../tickets/presentation/widgets/app_drawer.dart';

class ConfiguracionScreen extends StatefulWidget {
  final int paginaInicial;
  const ConfiguracionScreen({super.key, this.paginaInicial = 0});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
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
    final cfg = context.read<ConfigProvider>().config;
    _semanaCtrl =
        TextEditingController(text: cfg.precioAdultoSemana.toStringAsFixed(2));
    _findeCtrl =
        TextEditingController(text: cfg.precioAdultoFinde.toStringAsFixed(2));
    _ninoSemanaCtrl =
        TextEditingController(text: cfg.precioNinoSemana.toStringAsFixed(2));
    _ninoFindeCtrl =
        TextEditingController(text: cfg.precioNinoFinde.toStringAsFixed(2));
    _impresoraCtrl =
        TextEditingController(text: cfg.nombreImpresora);
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

  Future<void> _guardarPrecios() async {
    final adultoSemana = double.tryParse(_semanaCtrl.text);
    final adultoFinde = double.tryParse(_findeCtrl.text);
    final ninoSemana = double.tryParse(_ninoSemanaCtrl.text);
    final ninoFinde = double.tryParse(_ninoFindeCtrl.text);
    if (adultoSemana == null ||
        adultoFinde == null ||
        ninoSemana == null ||
        ninoFinde == null ||
        adultoSemana <= 0 ||
        adultoFinde <= 0 ||
        ninoSemana <= 0 ||
        ninoFinde <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa precios válidos (todos > 0)')));
      return;
    }
    await context.read<ConfigProvider>().actualizarPrecios(
          adultoSemana: adultoSemana,
          adultoFinde: adultoFinde,
          ninoSemana: ninoSemana,
          ninoFinde: ninoFinde,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Precios guardados'),
        backgroundColor: Color(0xFF1565C0)));
  }

  Future<void> _guardarImpresora() async {
    await context
        .read<ConfigProvider>()
        .actualizarImpresora(_impresoraCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impresora guardada'),
        backgroundColor: Color(0xFF1565C0)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: AppDrawer(pantalla: 'config'),
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
          // ── Tab Precios ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PreciosCard(
                          titulo: 'Lun – Vie',
                          icono: Icons.work_rounded,
                          color: const Color(0xFF0D47A1),
                          ctrlAdulto: _semanaCtrl,
                          ctrlNino: _ninoSemanaCtrl,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PreciosCard(
                          titulo: 'Sáb – Dom',
                          icono: Icons.wb_sunny_rounded,
                          color: const Color(0xFFE65100),
                          ctrlAdulto: _findeCtrl,
                          ctrlNino: _ninoFindeCtrl,
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
          // ── Tab Impresora ────────────────────────────────────────────────
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

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PreciosCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final TextEditingController ctrlAdulto;
  final TextEditingController ctrlNino;

  const _PreciosCard({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.ctrlAdulto,
    required this.ctrlNino,
  });

  InputDecoration _deco(Color c) => InputDecoration(
        prefixText: 'S/ ',
        isDense: true,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: c, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 6),
            Text(titulo,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.person_rounded, color: color, size: 16),
            const SizedBox(width: 4),
            Text('Adulto',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: ctrlAdulto,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            decoration: _deco(color),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.child_care_rounded, color: color, size: 16),
            const SizedBox(width: 4),
            Text('Niño',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: ctrlNino,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            decoration: _deco(color),
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
              offset: const Offset(0, 3))
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
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
