import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  Future<TicketModel> agregarTicket({
    required int adultos,
    required int ninos,
    required double monto,
    required String metodoPago,
  }) async {
    final db = await _db;
    final ahora = DateTime.now();
    late int id;
    late int ticketId;

    // Transacción atómica: inserta el registro y luego asigna
    // ticket_id = 84000 + id (basado en autoincrement — nunca colisiona).
    await db.transaction((txn) async {
      id = await txn.insert('tickets', {
        'ticket_id': 0,
        'adultos': adultos,
        'ninos': ninos,
        'monto': monto,
        'metodo_pago': metodoPago,
        'hora': ahora.toIso8601String(),
      });
      ticketId = 84000 + id;
      await txn.update(
        'tickets',
        {'ticket_id': ticketId},
        where: 'id = ?',
        whereArgs: [id],
      );
    });

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
