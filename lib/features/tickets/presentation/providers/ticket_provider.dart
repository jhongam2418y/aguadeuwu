import 'package:flutter/foundation.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';

class TicketProvider extends ChangeNotifier {
  final _repo = TicketRepository.instance;

  List<TicketModel> _ticketsHoy = [];
  bool _cargando = false;
  String? _error;

  List<TicketModel> get ticketsHoy => List.unmodifiable(_ticketsHoy);
  bool get cargando => _cargando;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> cargarTicketsHoy() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _ticketsHoy = await _repo.obtenerTicketsHoy();
    } catch (e) {
      _ticketsHoy = [];
      _error = 'Error al cargar tickets: $e';
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
    try {
      await _repo.anularTicket(id);
      final idx = _ticketsHoy.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _ticketsHoy[idx] = _ticketsHoy[idx].copyWith(anulado: true);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error al anular ticket: $e';
      notifyListeners();
    }
  }

  Future<List<TicketModel>> obtenerTicketsPorRango(DateTime desde, DateTime hasta) {
    return _repo.obtenerTicketsPorRango(desde, hasta);
  }
}
