class ConfigModel {
  final double precioAdultoSemana;
  final double precioAdultoFinde;
  final double precioNinoSemana;
  final double precioNinoFinde;
  final String nombreImpresora;

  const ConfigModel({
    required this.precioAdultoSemana,
    required this.precioAdultoFinde,
    required this.precioNinoSemana,
    required this.precioNinoFinde,
    required this.nombreImpresora,
  });

  factory ConfigModel.defaults() => const ConfigModel(
        precioAdultoSemana: 8.0,
        precioAdultoFinde: 10.0,
        precioNinoSemana: 5.0,
        precioNinoFinde: 7.0,
        nombreImpresora: '',
      );

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      precioAdultoSemana: (map['precio_adulto_semana'] as num).toDouble(),
      precioAdultoFinde: (map['precio_adulto_finde'] as num).toDouble(),
      precioNinoSemana: (map['precio_nino_semana'] as num).toDouble(),
      precioNinoFinde: (map['precio_nino_finde'] as num).toDouble(),
      nombreImpresora: map['nombre_impresora'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'precio_adulto_semana': precioAdultoSemana,
      'precio_adulto_finde': precioAdultoFinde,
      'precio_nino_semana': precioNinoSemana,
      'precio_nino_finde': precioNinoFinde,
      'nombre_impresora': nombreImpresora,
    };
  }

  ConfigModel copyWith({
    double? precioAdultoSemana,
    double? precioAdultoFinde,
    double? precioNinoSemana,
    double? precioNinoFinde,
    String? nombreImpresora,
  }) {
    return ConfigModel(
      precioAdultoSemana: precioAdultoSemana ?? this.precioAdultoSemana,
      precioAdultoFinde: precioAdultoFinde ?? this.precioAdultoFinde,
      precioNinoSemana: precioNinoSemana ?? this.precioNinoSemana,
      precioNinoFinde: precioNinoFinde ?? this.precioNinoFinde,
      nombreImpresora: nombreImpresora ?? this.nombreImpresora,
    );
  }
}
