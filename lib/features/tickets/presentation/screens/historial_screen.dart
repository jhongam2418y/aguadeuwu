import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().cargarTicketsHoy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final registros = provider.ticketsHoy;
    final total = registros.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                          size: 20, color: Color(0xFF0052CC)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tickets Emitidos Hoy',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF0D1B2A))),
                        Text('Resumen de operaciones recientes',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
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
                    child: Text('$total Total',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B6FD4))),
                  ),

                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            if (provider.cargando)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (registros.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No hay tickets emitidos hoy',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Row(
                        children: [
                          _ThCell(text: 'ID TICKET', flex: 3),
                          _ThCell(text: 'DETALLE', flex: 3),
                          _ThCell(text: 'MONTO', flex: 2, right: true),
                          _ThCell(text: 'HORA', flex: 2, right: true),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: registros.length,
                        separatorBuilder: (_, _) => const Divider(
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
                                  child: Text('#TK-${r.ticketId}',
                                      style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                      '${r.adultos} Ad. / ${r.ninos} Niñ.',
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                      'S/ ${r.monto.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF0D1B2A))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('$h:$m',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
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
      child: Text(text,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5)),
    );
  }
}
