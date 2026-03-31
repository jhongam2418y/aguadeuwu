import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';

// ─── Constantes de diseño ────────────────────────────────────────────────────
abstract final class _C {
  static const primary     = Color(0xFF0052CC);
  static const primarySoft = Color(0xFFEFF4FF);
  static const primaryBorder = Color(0xFF90B4F9);
  static const primaryText = Color(0xFF3B6FD4);
  static const idBlue      = Color(0xFF2563EB);
  static const text        = Color(0xFF1A1A1A);
  static const background  = Color(0xFFF0F7FF);
  static const rowAlt      = Color(0xFFFAFBFF);
  static const headerBg    = Color(0xFFF0F4FF);
}

// Formateador reutilizable — creado una sola vez
final _fmtHora = DateFormat('HH:mm');

// =============================================================================
// HistorialScreen
// =============================================================================
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TicketProvider>().cargarTicketsHoy(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final registros = provider.ticketsHoy;

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(total: registros.length),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _Body(
                cargando: provider.cargando,
                registros: registros,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _Header
// =============================================================================
class _Header extends StatelessWidget {
  final int total;
  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          // Botón volver
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.headerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: _C.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Título
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tickets Emitidos Hoy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _C.text,
                  ),
                ),
                Text(
                  'Resumen de operaciones recientes',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),

          // Badge total
          _TotalBadge(total: total),
        ],
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  final int total;
  const _TotalBadge({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _C.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primaryBorder, width: 1.5),
      ),
      child: Text(
        '$total Total',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _C.primaryText,
        ),
      ),
    );
  }
}

// =============================================================================
// _Body — decide qué mostrar según el estado
// =============================================================================
class _Body extends StatelessWidget {
  final bool cargando;
  final List<TicketModel> registros;
  const _Body({required this.cargando, required this.registros});

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (registros.isEmpty) {
      return const _EmptyState();
    }
    return _TicketTable(registros: registros);
  }
}

// =============================================================================
// _EmptyState  (const)
// =============================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No hay tickets emitidos hoy',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _TicketTable  — cabecera fija + lista desplazable
// =============================================================================
class _TicketTable extends StatelessWidget {
  final List<TicketModel> registros;
  const _TicketTable({required this.registros});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabecera fija
        const _TableHeader(),
        const Divider(height: 1, thickness: 1),
        // Filas
        Expanded(
          child: ListView.separated(
            itemCount: registros.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              thickness: 1,
              indent: 18,
              endIndent: 18,
            ),
            itemBuilder: (_, i) => _TicketRow(
              registro: registros[i],
              isEven: i.isEven,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _TableHeader  (const)
// =============================================================================
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: const Row(
        children: [
          _ThCell(text: 'ID TICKET', flex: 3),
          _ThCell(text: 'DETALLE',   flex: 3),
          _ThCell(text: 'MONTO',     flex: 2, right: true),
          _ThCell(text: 'HORA',      flex: 2, right: true),
        ],
      ),
    );
  }
}

// =============================================================================
// _TicketRow
// =============================================================================
class _TicketRow extends StatelessWidget {
  final TicketModel registro;
  final bool isEven;
  const _TicketRow({required this.registro, required this.isEven});

  @override
  Widget build(BuildContext context) {
    // Formatos calculados una vez por fila
    final horaStr = _fmtHora.format(registro.hora);

    return Container(
      color: isEven ? Colors.white : _C.rowAlt,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // ID
          Expanded(
            flex: 3,
            child: Text(
              '#TK-${registro.ticketId}',
              style: const TextStyle(
                color: _C.idBlue,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Detalle
          Expanded(
            flex: 3,
            child: Text(
              '${registro.adultos} Ad. / ${registro.ninos} Niñ.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          // Monto
          Expanded(
            flex: 2,
            child: Text(
              'S/ ${registro.monto.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _C.text,
              ),
            ),
          ),
          // Hora
          Expanded(
            flex: 2,
            child: Text(
              horaStr,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ThCell  (const)
// =============================================================================
class _ThCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool right;
  const _ThCell({required this.text, required this.flex, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}