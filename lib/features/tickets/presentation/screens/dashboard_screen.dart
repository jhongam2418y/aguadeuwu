import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../configuracion/presentation/providers/config_provider.dart';
import '../../../configuracion/presentation/screens/configuracion_screen.dart';
import '../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import 'boleteria_screen.dart';

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
    });
  }

  bool get _esFinde => DateTime.now().weekday >= 6;

  Future<void> _irABoleteria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BoleteriaScreen()),
    );
    if (mounted) context.read<TicketProvider>().cargarTicketsHoy();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final cfg = context.watch<ConfigProvider>();
    final tickets = provider.ticketsHoy;
    final totalIngresos = tickets.fold<double>(0, (s, t) => s + t.monto);

    final String diaLabel = _esFinde ? 'Fin de semana' : 'Día de semana';
    final String fechaHoy =
        DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Row(
          children: [
            // ─── Panel izquierdo ──────────────────────────────────────
            Expanded(
              flex: 55,
              child: Column(
                children: [
                  _TopBar(
                    onSettingsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConfiguracionScreen()),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Saludo
                          _Greeting(fecha: fechaHoy, diaLabel: diaLabel),
                          const SizedBox(height: 20),

                          // Stats
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.confirmation_number_rounded,
                                  iconColor: const Color(0xFF1565C0),
                                  bgColor: const Color(0xFFE3F0FF),
                                  label: 'Tickets Hoy',
                                  value: '${tickets.length}',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.payments_rounded,
                                  iconColor: const Color(0xFF2E7D32),
                                  bgColor: const Color(0xFFE8F5E9),
                                  label: 'Ingresos Hoy',
                                  value:
                                      'S/ ${totalIngresos.toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Precios del día
                          _PreciosCard(cfg: cfg, esFinde: _esFinde),
                          const SizedBox(height: 28),

                          // Botón Nuevo Ticket
                          _NuevoTicketButton(onTap: _irABoleteria),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Divider ─────────────────────────────────────────────
            Container(width: 1.5, color: const Color(0xFFCCDDFF)),

            // ─── Panel derecho — Historial ────────────────────────────
            Expanded(
              flex: 45,
              child: _HistorialPanel(
                tickets: tickets,
                cargando: provider.cargando,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;
  const _TopBar({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PISCIGRANJA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3)),
                Text('Sistema de Boletería',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 26),
            tooltip: 'Configuración',
          ),
        ],
      ),
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  final String fecha;
  final String diaLabel;
  const _Greeting({required this.fecha, required this.diaLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bienvenido',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D1B3E))),
        const SizedBox(height: 4),
        Text(fecha,
            style: const TextStyle(fontSize: 14, color: Color(0xFF607DB0))),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(diaLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0))),
        ),
      ],
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

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
              offset: const Offset(0, 4))
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF607DB0),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1B3E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Precios del día ─────────────────────────────────────────────────────────

class _PreciosCard extends StatelessWidget {
  final ConfigProvider cfg;
  final bool esFinde;
  const _PreciosCard({required this.cfg, required this.esFinde});

  @override
  Widget build(BuildContext context) {
    final adulto = esFinde ? cfg.precioAdultoFinde : cfg.precioAdultoSemana;
    final nino = esFinde ? cfg.precioNinoFinde : cfg.precioNinoSemana;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarifas vigentes',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF607DB0))),
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
  const _TarifaItem(
      {required this.icon, required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF607DB0))),
            Text('S/ ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B3E))),
          ],
        ),
      ],
    );
  }
}

// ─── Botón Nuevo Ticket ───────────────────────────────────────────────────────

class _NuevoTicketButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NuevoTicketButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.white, size: 56),
              SizedBox(height: 14),
              Text('Nuevo Ticket',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              SizedBox(height: 6),
              Text('Toca para emitir un nuevo ticket de ingreso',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel historial ──────────────────────────────────────────────────────────

class _HistorialPanel extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool cargando;
  const _HistorialPanel({required this.tickets, required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFD0E4FF), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: Color(0xFF1565C0), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historial del Día',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1B3E))),
                    Text('Tickets emitidos hoy',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF607DB0))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${tickets.length} total',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0))),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: cargando
              ? const Center(child: CircularProgressIndicator())
              : tickets.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      itemCount: tickets.length,
                      itemBuilder: (_, i) => _TicketItem(ticket: tickets[i]),
                    ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Sin tickets hoy',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text('Los tickets emitidos aparecerán aquí',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final TicketModel ticket;
  const _TicketItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final hora =
        DateFormat('HH:mm').format(ticket.hora);
    final totalPax = ticket.adultos + ticket.ninos;
    final esEfectivo = ticket.metodoPago == 'efectivo';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Ticket ID badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#${ticket.ticketId.toString().padLeft(4, '0')}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0)),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paxLabel(ticket.adultos, ticket.ninos),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3E)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(hora,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(width: 8),
                      Icon(
                        esEfectivo
                            ? Icons.money_rounded
                            : Icons.credit_card_rounded,
                        size: 11,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        esEfectivo ? 'Efectivo' : 'Transferencia',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Monto + pax count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${ticket.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B3E)),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalPax pax',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _paxLabel(int adultos, int ninos) {
    final parts = <String>[];
    if (adultos > 0) parts.add('$adultos adulto${adultos > 1 ? 's' : ''}');
    if (ninos > 0) parts.add('$ninos niño${ninos > 1 ? 's' : ''}');
    return parts.join(' + ');
  }
}
