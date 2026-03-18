import 'package:flutter/foundation.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/config_repository.dart';

class ConfigProvider extends ChangeNotifier {
  final _repo = ConfigRepository.instance;

  ConfigModel _config = ConfigModel.defaults();

  ConfigModel get config => _config;

  /// weekday: 1 = Lunes … 7 = Domingo (DateTime.weekday)
  double precioAdulto(int weekday) => _config.precioAdultoDia(weekday);
  double precioNino(int weekday) => _config.precioNinoDia(weekday);

  String get nombreImpresora => _config.nombreImpresora;

  Future<void> cargar() async {
    _config = await _repo.cargar();
    notifyListeners();
  }

  Future<void> actualizarPrecios({
    required List<double> preciosAdulto,
    required List<double> preciosNino,
  }) async {
    _config = _config.copyWith(
      preciosAdulto: preciosAdulto,
      preciosNino: preciosNino,
    );
    await _repo.guardar(_config);
    notifyListeners();
  }

  Future<void> actualizarImpresora(String nombre) async {
    _config = _config.copyWith(nombreImpresora: nombre);
    await _repo.guardar(_config);
    notifyListeners();
  }
}
