class TicketModel {
  final int id;
  final int ticketId;
  final int adultos;
  final int ninos;
  final double monto;
  final String metodoPago;
  final DateTime hora;
  final bool anulado;

  const TicketModel({
    required this.id,
    required this.ticketId,
    required this.adultos,
    required this.ninos,
    required this.monto,
    required this.metodoPago,
    required this.hora,
    this.anulado = false,
  });

  TicketModel copyWith({bool? anulado}) {
    return TicketModel(
      id: id,
      ticketId: ticketId,
      adultos: adultos,
      ninos: ninos,
      monto: monto,
      metodoPago: metodoPago,
      hora: hora,
      anulado: anulado ?? this.anulado,
    );
  }

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as int,
      ticketId: map['ticket_id'] as int,
      adultos: map['adultos'] as int,
      ninos: map['ninos'] as int,
      monto: (map['monto'] as num).toDouble(),
      metodoPago: map['metodo_pago'] as String,
      hora: DateTime.parse(map['hora'] as String),
      anulado: (map['anulado'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticket_id': ticketId,
      'adultos': adultos,
      'ninos': ninos,
      'monto': monto,
      'metodo_pago': metodoPago,
      'hora': hora.toIso8601String(),
      'anulado': anulado ? 1 : 0,
    };
  }
}
