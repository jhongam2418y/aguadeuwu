import 'package:flutter_test/flutter_test.dart';
import 'package:piscigranja/features/tickets/data/models/ticket_model.dart';

void main() {
  final baseTime = DateTime(2026, 4, 1, 10, 30);

  group('TicketModel', () {
    test('fromMap crea el modelo correctamente', () {
      final map = {
        'id': 1,
        'ticket_id': 84001,
        'adultos': 2,
        'ninos': 1,
        'monto': 21.0,
        'metodo_pago': 'efectivo',
        'hora': baseTime.toIso8601String(),
        'anulado': 0,
      };

      final ticket = TicketModel.fromMap(map);

      expect(ticket.id, 1);
      expect(ticket.ticketId, 84001);
      expect(ticket.adultos, 2);
      expect(ticket.ninos, 1);
      expect(ticket.monto, 21.0);
      expect(ticket.metodoPago, 'efectivo');
      expect(ticket.hora, baseTime);
      expect(ticket.anulado, false);
    });

    test('fromMap con anulado=1 retorna anulado=true', () {
      final map = {
        'id': 2,
        'ticket_id': 84002,
        'adultos': 1,
        'ninos': 0,
        'monto': 8.0,
        'metodo_pago': 'yape',
        'hora': baseTime.toIso8601String(),
        'anulado': 1,
      };

      expect(TicketModel.fromMap(map).anulado, true);
    });

    test('fromMap usa false como default cuando anulado no existe', () {
      final map = {
        'id': 3,
        'ticket_id': 84003,
        'adultos': 0,
        'ninos': 2,
        'monto': 10.0,
        'metodo_pago': 'tarjeta',
        'hora': baseTime.toIso8601String(),
        // 'anulado' ausente
      };

      expect(TicketModel.fromMap(map).anulado, false);
    });

    test('toMap produce el mapa correcto', () {
      final ticket = TicketModel(
        id: 5,
        ticketId: 84005,
        adultos: 3,
        ninos: 2,
        monto: 34.0,
        metodoPago: 'efectivo',
        hora: baseTime,
        anulado: false,
      );

      final map = ticket.toMap();

      expect(map['ticket_id'], 84005);
      expect(map['adultos'], 3);
      expect(map['ninos'], 2);
      expect(map['monto'], 34.0);
      expect(map['metodo_pago'], 'efectivo');
      expect(map['hora'], baseTime.toIso8601String());
      expect(map['anulado'], 0);
    });

    test('toMap codifica anulado=true como 1', () {
      final ticket = TicketModel(
        id: 6,
        ticketId: 84006,
        adultos: 1,
        ninos: 0,
        monto: 8.0,
        metodoPago: 'efectivo',
        hora: baseTime,
        anulado: true,
      );

      expect(ticket.toMap()['anulado'], 1);
    });

    test('copyWith sobreescribe anulado y conserva el resto', () {
      final original = TicketModel(
        id: 7,
        ticketId: 84007,
        adultos: 2,
        ninos: 1,
        monto: 23.0,
        metodoPago: 'efectivo',
        hora: baseTime,
      );

      final anulado = original.copyWith(anulado: true);

      expect(anulado.anulado, true);
      expect(anulado.id, original.id);
      expect(anulado.ticketId, original.ticketId);
      expect(anulado.monto, original.monto);
      expect(anulado.adultos, original.adultos);
    });

    test('fromMap → toMap es idempotente (roundtrip)', () {
      final map = {
        'id': 8,
        'ticket_id': 84008,
        'adultos': 2,
        'ninos': 2,
        'monto': 26.0,
        'metodo_pago': 'tarjeta',
        'hora': baseTime.toIso8601String(),
        'anulado': 0,
      };

      final restored = TicketModel.fromMap(map).toMap();

      expect(restored['ticket_id'], map['ticket_id']);
      expect(restored['adultos'], map['adultos']);
      expect(restored['ninos'], map['ninos']);
      expect(restored['monto'], map['monto']);
      expect(restored['metodo_pago'], map['metodo_pago']);
      expect(restored['hora'], map['hora']);
      expect(restored['anulado'], map['anulado']);
    });
  });
}
