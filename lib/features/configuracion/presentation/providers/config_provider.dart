import 'package:flutter/foundation.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/config_repository.dart';

class ConfigProvider extends ChangeNotifier {
  final _repo = ConfigRepository.instance;

  ConfigModel _config = ConfigModel.defaults();

  ConfigModel get config => _config;

  double get precioAdultoSemana => _config.precioAdultoSemana;
  double get precioAdultoFinde => _config.precioAdultoFinde;
  double get precioNinoSemana => _config.precioNinoSemana;
  double get precioNinoFinde => _config.precioNinoFinde;
  String get nombreImpresora => _config.nombreImpresora;

  Future<void> cargar() async {
    _config = await _repo.cargar();
    notifyListeners();
  }

  Future<void> actualizarPrecios({
    required double adultoSemana,
    required double adultoFinde,
    required double ninoSemana,
    required double ninoFinde,
  }) async {
    _config = _config.copyWith(
      precioAdultoSemana: adultoSemana,
      precioAdultoFinde: adultoFinde,
      precioNinoSemana: ninoSemana,
      precioNinoFinde: ninoFinde,
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
