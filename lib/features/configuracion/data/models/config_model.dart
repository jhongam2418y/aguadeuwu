class ConfigModel {
  /// Precios por día: índice 0 = Lunes, 1 = Martes, ..., 6 = Domingo
  final List<double> preciosAdulto;
  final List<double> preciosNino;
  final String nombreImpresora;

  static const List<String> nombresDias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  static const _adultoCols = [
    'precio_adulto_lun', 'precio_adulto_mar', 'precio_adulto_mie',
    'precio_adulto_jue', 'precio_adulto_vie', 'precio_adulto_sab',
    'precio_adulto_dom',
  ];
  static const _ninoCols = [
    'precio_nino_lun', 'precio_nino_mar', 'precio_nino_mie',
    'precio_nino_jue', 'precio_nino_vie', 'precio_nino_sab',
    'precio_nino_dom',
  ];

  const ConfigModel({
    required this.preciosAdulto,
    required this.preciosNino,
    required this.nombreImpresora,
  });

  factory ConfigModel.defaults() => ConfigModel(
        preciosAdulto: [8.0, 8.0, 8.0, 8.0, 8.0, 10.0, 10.0],
        preciosNino:   [5.0, 5.0, 5.0, 5.0, 5.0,  7.0,  7.0],
        nombreImpresora: '',
      );

  /// weekday: 1 = Lunes … 7 = Domingo (DateTime.weekday)
  double precioAdultoDia(int weekday) => preciosAdulto[(weekday - 1) % 7];
  double precioNinoDia(int weekday)   => preciosNino[(weekday - 1) % 7];

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      preciosAdulto: _adultoCols.map((c) => (map[c] as num).toDouble()).toList(),
      preciosNino:   _ninoCols.map((c) => (map[c] as num).toDouble()).toList(),
      nombreImpresora: map['nombre_impresora'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{'id': 1, 'nombre_impresora': nombreImpresora};
    for (var i = 0; i < 7; i++) {
      m[_adultoCols[i]] = preciosAdulto[i];
      m[_ninoCols[i]]   = preciosNino[i];
    }
    return m;
  }

  ConfigModel copyWith({
    List<double>? preciosAdulto,
    List<double>? preciosNino,
    String? nombreImpresora,
  }) {
    return ConfigModel(
      preciosAdulto:   preciosAdulto   ?? this.preciosAdulto,
      preciosNino:     preciosNino     ?? this.preciosNino,
      nombreImpresora: nombreImpresora ?? this.nombreImpresora,
    );
  }
}
