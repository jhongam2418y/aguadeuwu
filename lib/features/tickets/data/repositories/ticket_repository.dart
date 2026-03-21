import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  // Genera un ID de ticket único basado en la hora actual
  int _generarTicketId() =>
      84000 + (DateTime.now().millisecondsSinceEpoch % 99999);

  Future<TicketModel> agregarTicket({
    required int adultos,
    required int ninos,
    required double monto,
    required String metodoPago,
  }) async {
    final db = await _db;
    final ticketId = _generarTicketId();
    final ahora = DateTime.now();

    final map = {
      'ticket_id': ticketId,
      'adultos': adultos,
      'ninos': ninos,
      'monto': monto,
      'metodo_pago': metodoPago,
      'hora': ahora.toIso8601String(),
    };

    final id = await db.insert('tickets', map);

    return TicketModel(
      id: id,
      ticketId: ticketId,
      adultos: adultos,
      ninos: ninos,
      monto: monto,
      metodoPago: metodoPago,
      hora: ahora,
    );
  }

  /// Devuelve todos los tickets del día actual, orden descendente.
  Future<List<TicketModel>> obtenerTicketsHoy() async {
    final hoy = DateTime.now();
    return obtenerTicketsPorRango(hoy, hoy);
  }

  /// Marca un ticket como anulado.
  Future<void> anularTicket(int id) async {
    final db = await _db;
    await db.update(
      'tickets',
      {'anulado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Devuelve tickets en un rango de fechas.
  Future<List<TicketModel>> obtenerTicketsPorRango(DateTime desde, DateTime hasta) async {
    final db = await _db;
    final inicioStr = DateTime(desde.year, desde.month, desde.day).toIso8601String();
    final finStr = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59).toIso8601String();

    final rows = await db.query(
      'tickets',
      where: 'hora BETWEEN ? AND ?',
      whereArgs: [inicioStr, finStr],
      orderBy: 'hora DESC',
    );

    return rows.map(TicketModel.fromMap).toList();
  }
}
