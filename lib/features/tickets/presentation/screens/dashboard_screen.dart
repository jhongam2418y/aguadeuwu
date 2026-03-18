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
    final ticketsActivos = tickets.where((t) => !t.anulado).toList();
    final totalIngresos = ticketsActivos.fold<double>(0, (s, t) => s + t.monto);

    final String diaLabel = DateFormat('EEEE', 'es').format(DateTime.now());
    final String fechaHoy =
        DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());
    final String diaLabelUpper = diaLabel.toUpperCase();
    final bool esFinde = DateTime.now().weekday >= 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            //  Top bar  ancho completo 
            _TopBar(
              onSettingsTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConfiguracionScreen()),
              ),
            ),

            //  Contenido principal 
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saludo
                  _Greeting(fecha: fechaHoy, diaLabel: diaLabelUpper),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.confirmation_number_rounded,
                            iconColor: const Color(0xFF0052CC),
                            bgColor: const Color(0xFFE3F0FF),
                            label: 'Tickets Hoy',
                            value: '${ticketsActivos.length}',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.payments_rounded,
                            iconColor: const Color(0xFF21BA45),
                            bgColor: const Color(0xFFE8F5E9),
                            label: 'Ingresos Hoy',
                            value: 'S/ ${totalIngresos.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Precios del día
                    _PreciosCard(cfg: cfg, esFinde: esFinde),
                    const SizedBox(height: 24),

                    // Botón Nuevo Ticket centrado
                    _NuevoTicketButton(onTap: _irABoleteria),
                    const SizedBox(height: 24),

                    //  Historial integrado 
                    _HistorialInline(
                      tickets: tickets,
                      cargando: provider.cargando,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Top bar 

class _TopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;
  const _TopBar({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF003D99)],
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
           Text('SISTEMA DE BOLETERÍA',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
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

//  Greeting 

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
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(fecha,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF607DB0))),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(diaLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0052CC),
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      ],
    );
  }
}

//  Stat card 

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
                Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF607DB0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Precios del día 

class _PreciosCard extends StatelessWidget {
  final ConfigProvider cfg;
  final bool esFinde;
  const _PreciosCard({required this.cfg, required this.esFinde});

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
              color: const Color(0xFF0052CC).withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TARIFAS VIGENTES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF607DB0),
                  letterSpacing: 0.8)),
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
        Icon(icon, size: 20, color: const Color(0xFF0052CC)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Color(0xFF607DB0))),
            Text('S/ ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A))),
          ],
        ),
      ],
    );
  }
}

//  Botón Nuevo Ticket 

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
              colors: [Color(0xFF137FEC), Color(0xFF003D99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.white, size: 52),
              SizedBox(height: 12),
              Text('Nuevo Ticket',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              SizedBox(height: 4),
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

//  Historial integrado 

class _HistorialInline extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool cargando;
  const _HistorialInline({required this.tickets, required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado de sección
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded,
                color: Color(0xFF0052CC), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('TICKETS DE HOY',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.5)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${tickets.length} EMITIDOS',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF0052CC))),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Contenido
        if (cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tickets.isEmpty)
          _EmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            itemBuilder: (_, i) => _TicketItem(ticket: tickets[i]),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Sin tickets hoy',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text('Los tickets emitidos aparecerán aquí',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final TicketModel ticket;
  const _TicketItem({required this.ticket});

  Future<void> _confirmarAnulacion(BuildContext context) async {
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
    if (confirmar == true && context.mounted) {
      await context.read<TicketProvider>().anularTicket(ticket.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat('HH:mm').format(ticket.hora);
    final totalPax = ticket.adultos + ticket.ninos;
    final esEfectivo = ticket.metodoPago == 'efectivo';
    final anulado = ticket.anulado;

    return GestureDetector(
      onLongPress: anulado ? null : () => _confirmarAnulacion(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: anulado ? const Color(0xFFFFF0F0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: (anulado ? Colors.red : const Color(0xFF0052CC))
                    .withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
          border: anulado
              ? Border.all(color: Colors.red.shade200, width: 1)
              : null,
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
                  color: anulado
                      ? Colors.red.shade50
                      : const Color(0xFFE3F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${ticket.ticketId.toString().padLeft(4, '0')}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: anulado
                          ? Colors.red.shade400
                          : const Color(0xFF0052CC)),
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: anulado
                              ? Colors.grey.shade400
                              : const Color(0xFF1A1A1A),
                          decoration:
                              anulado ? TextDecoration.lineThrough : null),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(hora,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
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
                          ticket.metodoPago[0].toUpperCase() +
                              ticket.metodoPago.substring(1),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Monto + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${ticket.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: anulado
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A1A),
                        decoration:
                            anulado ? TextDecoration.lineThrough : null),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: anulado
                          ? Colors.red.shade50
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      anulado ? 'ANULADO' : '$totalPax pax',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: anulado
                              ? Colors.red.shade400
                              : const Color(0xFF21BA45)),
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

  String _paxLabel(int adultos, int ninos) {
    final parts = <String>[];
    if (adultos > 0) parts.add('$adultos adulto${adultos > 1 ? 's' : ''}');
    if (ninos > 0) parts.add('$ninos niño${ninos > 1 ? 's' : ''}');
    return parts.join(' + ');
  }
}
