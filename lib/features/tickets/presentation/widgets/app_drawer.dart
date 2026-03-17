import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../screens/historial_screen.dart';
import '../../../configuracion/presentation/screens/configuracion_screen.dart';

class AppDrawer extends StatelessWidget {
  /// 'tickets' | 'historial' | 'config'
  final String pantalla;
  const AppDrawer({super.key, required this.pantalla});

  void _ir(BuildContext context, String destino, {int tab = 0}) {
    final nav = Navigator.of(context);
    nav.pop();
    switch (destino) {
      case 'tickets':
        nav.popUntil((r) => r.isFirst);
      case 'historial':
        if (pantalla == 'historial') return;
        if (pantalla != 'tickets') nav.popUntil((r) => r.isFirst);
        nav.push(MaterialPageRoute(builder: (_) => const HistorialScreen()));
      case 'config':
        if (pantalla == 'config') return;
        if (pantalla != 'tickets') nav.popUntil((r) => r.isFirst);
        nav.push(MaterialPageRoute(
            builder: (_) => ConfiguracionScreen(paginaInicial: tab)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1565C0);
    const activeBg = Color(0xFFE8F0FE);
    final cfg = context.watch<ConfigProvider>();

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
                Icon(Icons.water_rounded, color: Colors.white70, size: 36),
                SizedBox(height: 10),
                Text('PISCIGRANJA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                Text('Boletería',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          item(
            clave: 'tickets',
            icono: Icons.confirmation_number_rounded,
            titulo: 'Tickets',
            subtitulo: 'Emitir nuevos tickets',
            onTap: () => _ir(context, 'tickets'),
          ),
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
          ListTile(
            selected: pantalla == 'config',
            selectedTileColor: activeBg,
            leading: const Icon(Icons.sell_rounded, color: activeColor),
            title: const Text('Precio del Ticket',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
                'Adulto S/ ${cfg.precioAdultoSemana.toStringAsFixed(2)}'
                '  ·  Finde S/ ${cfg.precioAdultoFinde.toStringAsFixed(2)}'),
            onTap: () => _ir(context, 'config', tab: 0),
          ),
          ListTile(
            leading: const Icon(Icons.print_rounded, color: activeColor),
            title: const Text('Impresora',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(cfg.nombreImpresora.isEmpty
                ? 'No configurada'
                : cfg.nombreImpresora),
            onTap: () => _ir(context, 'config', tab: 1),
          ),
        ],
      ),
    );
  }
}
