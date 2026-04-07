import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/update/update_dialog.dart';
import '../../../configuracion/presentation/providers/config_provider.dart';
import '../../../configuracion/presentation/screens/configuracion_screen.dart';
import '../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import 'boleteria_screen.dart';

// ─── Constantes de diseño centralizadas ──────────────────────────────────────
// ─── Aliases a AppColors (fuente única de verdad) ────────────────────────────
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

// ─── Formateadores reutilizables (creados una sola vez) ──────────────────────
final _fmtHora = DateFormat('HH:mm');
final _fmtDia = DateFormat('EEEE', 'es');
final _fmtFecha = DateFormat("EEEE d 'de' MMMM", 'es');

// Parsea el campo metodoPago — lógica centralizada en TicketModel.parsearMetodoPago

String _labelMetodo(String valor) {
  if (valor.isEmpty) return valor;
  return valor[0].toUpperCase() + valor.substring(1);
}

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
      // Verificar actualizaciones al iniciar (sin bloquear la UI)
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
    // Leemos providers una sola vez con Selector para reconstruir solo
    // los widgets que realmente dependen de cada dato.
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
                onNuevoTicket: _irABoleteria,
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
// _DashboardBody — isolado para que solo él se reconstruya con los providers
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
    final provider = context.watch<TicketProvider>();
    final cfg = context.watch<ConfigProvider>();

    final tickets = provider.ticketsHoy;
    final ticketsActivos = tickets.where((t) => !t.anulado).toList();
    final totalIngresos = ticketsActivos.fold<double>(0.0, (s, t) => s + t.monto);

    // ─── Layout fijo desktop táctil: 2 columnas sin scroll ──────────────────
    return Column(
      children: [
        // Banner de error visible si el provider tuvo un fallo
        if (provider.error != null)
          _ErrorBanner(
            message: provider.error!,
            onDismiss: provider.clearError,
          ),
        Expanded(child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Columna izquierda: estadísticas + tarifas + botón principal ───
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Greeting(
                    fecha: _fmtFecha.format(DateTime.now()),
                    diaLabel: _fmtDia.format(DateTime.now()).toUpperCase(),
                  ),
                  const SizedBox(height: 20),
                  // Tarjetas de resumen
                  Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.confirmation_number_rounded,
                        iconColor: _AppColors.primary,
                        bgColor: _AppColors.primaryLight,
                        label: 'Tickets Hoy',
                        value: '${ticketsActivos.length}',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_rounded,
                        iconColor: _AppColors.green,
                        bgColor: _AppColors.greenLight,
                        label: 'Ingresos Hoy',
                        value: 'S/ ${totalIngresos.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PagoDesgloseCard(tickets: ticketsActivos),
                const SizedBox(height: 14),
                _PreciosCard(cfg: cfg),
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
          // ── Columna derecha: historial a pantalla completa ─────────────────
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
                tickets: tickets,
                cargando: provider.cargando,
                onVerHistorial: onVerHistorial,
              ),
            ),
          ),
        ],
      ))),
      ],
    );
  }
}

// =============================================================================
// _TopBar  (const-safe: no depende de datos dinámicos)
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
          // Logo icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Título de la app
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PISCIGRANJA',
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
          // Fecha y día actuales
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
// _StatCard
// =============================================================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _AppColors.textSoft,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _AppColors.text,
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

// =============================================================================
// _PreciosCard  — esFinde eliminado: el precio ya viene directo del cfg
// =============================================================================
class _PreciosCard extends StatelessWidget {
  final ConfigProvider cfg;
  const _PreciosCard({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final weekday = DateTime.now().weekday;
    final adulto = cfg.precioAdulto(weekday);
    final nino = cfg.precioNino(weekday);

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
                  icon: Icons.person_rounded,
                  label: 'Adulto',
                  price: adulto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TarifaItem(
                  icon: Icons.child_care_rounded,
                  label: 'Niño',
                  price: nino,
                ),
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
  const _TarifaItem({required this.icon, required this.label, required this.price});

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

  // Decoración estática — se crea una sola vez
  static final _decoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF137FEC), _AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Color(0x660052CC), // 0x66 ≈ alpha 0.4
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
                  fontWeight: FontWeight.w400,
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
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header sticky
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
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

          // Body con scroll
          Expanded(
            child: _HistorialScroll(
              tickets: tickets,
              cargando: cargando,
            ),
          ),

          // Footer: acceso rápido al historial completo
          _HistorialFooter(onTap: onVerHistorial),
        ],
      ),
    );
  }
}

class _HistorialScroll extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool cargando;
  const _HistorialScroll({required this.tickets, required this.cargando});

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tickets.isEmpty) {
      return const _EmptyState();
    }
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

// =============================================================================
// _EmptyState  (ahora const)
// =============================================================================
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

  Future<void> _confirmarAnulacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Ticket'),
        content: Text(
          '¿Desea anular el ticket #${ticket.ticketId}? Esta acción no se puede deshacer.',
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
    // Variables locales para evitar accesos repetidos al objeto
    final anulado = ticket.anulado;
    final hora = _fmtHora.format(ticket.hora);
    final totalPax = ticket.adultos + ticket.ninos;
    final metodos = TicketModel.parsearMetodoPago(ticket.metodoPago);
    final esEfectivo = metodos.keys.length == 1 && metodos.keys.first == 'efectivo';

    // Colores derivados del estado — calculados una vez
    final idBgColor = anulado ? Colors.red.shade50 : _AppColors.primaryLight;
    final idTextColor = anulado ? Colors.red.shade400 : _AppColors.primary;
    final mainTextColor = anulado ? Colors.grey.shade400 : _AppColors.text;
    final badgeBgColor = anulado ? Colors.red.shade50 : _AppColors.greenLight;
    final badgeTextColor = anulado ? Colors.red.shade400 : _AppColors.green;
    final textDecoration = anulado ? TextDecoration.lineThrough : null;

    return GestureDetector(
      onLongPress: anulado ? null : () => _confirmarAnulacion(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: anulado ? AppColors.errorLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (anulado ? Colors.red : _AppColors.primary)
                  .withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: anulado
              ? Border.all(color: Colors.red.shade200)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ID badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: idBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${ticket.ticketId.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: idTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paxLabel(ticket.adultos, ticket.ninos),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: mainTextColor,
                        decoration: textDecoration,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          hora,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          esEfectivo
                              ? Icons.money_rounded
                              : Icons.phone_android_rounded,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          metodos.keys.map(_labelMetodo).join(' + '),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Monto + pax badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${ticket.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: mainTextColor,
                      decoration: textDecoration,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  /// Genera etiqueta de pasajeros: "2 adultos + 1 niño"
  static String _paxLabel(int adultos, int ninos) {
    final parts = <String>[];
    if (adultos > 0) parts.add('$adultos adulto${adultos > 1 ? 's' : ''}');
    if (ninos > 0) parts.add('$ninos niño${ninos > 1 ? 's' : ''}');
    return parts.join(' + ');
  }
}

// =============================================================================
// _HistorialFooter — botón de acceso al historial completo
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
// _ErrorBanner — muestra errores del provider con botón de cierre
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
                  fontWeight: FontWeight.w600),
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
// _PagoDesgloseCard — desglose de ingresos por método de pago
// =============================================================================
class _PagoDesgloseCard extends StatelessWidget {
  final List<TicketModel> tickets;
  const _PagoDesgloseCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    // Agrupa montos por método de pago (parsea formato con montos divididos)
    final porMetodo = <String, double>{};
    for (final t in tickets) {
      final metodos = TicketModel.parsearMetodoPago(t.metodoPago);
      if (metodos.values.every((v) => v != null)) {
        // Formato nuevo con montos explícitos
        for (final e in metodos.entries) {
          porMetodo[e.key] = (porMetodo[e.key] ?? 0) + e.value!;
        }
      } else {
        // Formato antiguo sin montos: acumular monto total al primer método
        final keys = metodos.keys.toList();
        porMetodo[keys[0]] = (porMetodo[keys[0]] ?? 0) + t.monto;
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
              for (final entry in porMetodo.entries) ...[
                Expanded(
                  child: _TarifaItem(
                    icon: entry.key == 'efectivo'
                        ? Icons.money_rounded
                        : Icons.phone_android_rounded,
                    label: _labelMetodo(entry.key),
                    price: entry.value,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}