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

  // ── Helpers para el campo metodoPago ──────────────────────────────────────
  // Formato del campo: "efectivo" | "efectivo+yape" | "efectivo:15.00+yape:5.00"

  /// Parsea metodoPago en un mapa método→monto (null si no hay monto explícito).
  static Map<String, double?> parsearMetodoPago(String metodoPago) {
    final result = <String, double?>{};
    for (final parte in metodoPago.split('+')) {
      final split = parte.split(':');
      final metodo = split[0].trim();
      final monto = split.length > 1 ? double.tryParse(split[1].trim()) : null;
      result[metodo] = monto;
    }
    return result;
  }

  /// Formatea una parte individual para mostrar al usuario.
  /// "efectivo" → "Efectivo"
  /// "efectivo:15.00" → "Efectivo: S/ 15.00"
  static String formatearParte(String parte) {
    final c = parte.indexOf(':');
    if (c < 0) {
      return parte.isEmpty ? parte : '${parte[0].toUpperCase()}${parte.substring(1)}';
    }
    final nombre = parte.substring(0, c).trim();
    final monto = parte.substring(c + 1).trim();
    return '${nombre[0].toUpperCase()}${nombre.substring(1)}: S/ $monto';
  }
}
