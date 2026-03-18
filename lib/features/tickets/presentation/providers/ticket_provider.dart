import 'package:flutter/foundation.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';

class TicketProvider extends ChangeNotifier {
  final _repo = TicketRepository.instance;

  List<TicketModel> _ticketsHoy = [];
  bool _cargando = false;

  List<TicketModel> get ticketsHoy => List.unmodifiable(_ticketsHoy);
  bool get cargando => _cargando;

  Future<void> cargarTicketsHoy() async {
    _cargando = true;
    notifyListeners();
    try {
      _ticketsHoy = await _repo.obtenerTicketsHoy();
    } catch (_) {
      _ticketsHoy = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<TicketModel> agregarTicket({
    required int adultos,
    required int ninos,
    required double monto,
    required String metodoPago,
  }) async {
    final ticket = await _repo.agregarTicket(
      adultos: adultos,
      ninos: ninos,
      monto: monto,
      metodoPago: metodoPago,
    );
    _ticketsHoy.insert(0, ticket);
    notifyListeners();
    return ticket;
  }

  Future<void> anularTicket(int id) async {
    await _repo.anularTicket(id);
    final idx = _ticketsHoy.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _ticketsHoy[idx] = _ticketsHoy[idx].copyWith(anulado: true);
    }
    notifyListeners();
  }

  Future<List<TicketModel>> obtenerTicketsPorRango(DateTime desde, DateTime hasta) {
    return _repo.obtenerTicketsPorRango(desde, hasta);
  }
}
