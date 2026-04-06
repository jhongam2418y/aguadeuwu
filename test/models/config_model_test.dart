import 'package:flutter_test/flutter_test.dart';
import 'package:piscigranja/features/configuracion/data/models/config_model.dart';

void main() {
  group('ConfigModel', () {
    test('defaults() retorna 7 días con precios de semana y fin de semana', () {
      final cfg = ConfigModel.defaults();

      expect(cfg.preciosAdulto.length, 7);
      expect(cfg.preciosNino.length, 7);
      expect(cfg.nombreImpresora, '');
      // Semana: 8.0 adulto, 5.0 niño
      expect(cfg.preciosAdulto[0], 8.0); // Lunes
      expect(cfg.preciosAdulto[4], 8.0); // Viernes
      expect(cfg.preciosNino[0], 5.0);
      // Fin de semana: 10.0 adulto, 7.0 niño
      expect(cfg.preciosAdulto[5], 10.0); // Sábado
      expect(cfg.preciosAdulto[6], 10.0); // Domingo
      expect(cfg.preciosNino[5], 7.0);
      expect(cfg.preciosNino[6], 7.0);
    });

    test('precioAdultoDia mapea weekday de DateTime (1=Lunes … 7=Domingo)', () {
      final cfg = ConfigModel.defaults();

      expect(cfg.precioAdultoDia(1), 8.0);  // Lunes
      expect(cfg.precioAdultoDia(5), 8.0);  // Viernes
      expect(cfg.precioAdultoDia(6), 10.0); // Sábado
      expect(cfg.precioAdultoDia(7), 10.0); // Domingo
    });

    test('precioNinoDia mapea weekday de DateTime', () {
      final cfg = ConfigModel.defaults();

      expect(cfg.precioNinoDia(1), 5.0);  // Lunes
      expect(cfg.precioNinoDia(5), 5.0);  // Viernes
      expect(cfg.precioNinoDia(6), 7.0);  // Sábado
      expect(cfg.precioNinoDia(7), 7.0);  // Domingo
    });

    test('copyWith sobreescribe nombreImpresora y conserva precios', () {
      final original = ConfigModel.defaults();
      final modificado = original.copyWith(nombreImpresora: 'POS-80C');

      expect(modificado.nombreImpresora, 'POS-80C');
      expect(modificado.preciosAdulto, original.preciosAdulto);
      expect(modificado.preciosNino, original.preciosNino);
    });

    test('copyWith sobreescribe preciosAdulto y conserva el resto', () {
      final original = ConfigModel.defaults();
      final nuevos = List<double>.filled(7, 12.0);
      final modificado = original.copyWith(preciosAdulto: nuevos);

      expect(modificado.preciosAdulto, everyElement(12.0));
      expect(modificado.preciosNino, original.preciosNino);
      expect(modificado.nombreImpresora, original.nombreImpresora);
    });

    test('fromMap parsea todas las columnas correctamente', () {
      final map = <String, dynamic>{
        'id': 1,
        'nombre_impresora': 'EPSON TM-T20',
        'precio_adulto_lun': 8.0,
        'precio_adulto_mar': 8.0,
        'precio_adulto_mie': 8.0,
        'precio_adulto_jue': 8.0,
        'precio_adulto_vie': 8.0,
        'precio_adulto_sab': 10.0,
        'precio_adulto_dom': 10.0,
        'precio_nino_lun': 5.0,
        'precio_nino_mar': 5.0,
        'precio_nino_mie': 5.0,
        'precio_nino_jue': 5.0,
        'precio_nino_vie': 5.0,
        'precio_nino_sab': 7.0,
        'precio_nino_dom': 7.0,
      };

      final cfg = ConfigModel.fromMap(map);

      expect(cfg.nombreImpresora, 'EPSON TM-T20');
      expect(cfg.preciosAdulto[5], 10.0); // Sábado
      expect(cfg.preciosNino[0], 5.0);    // Lunes
    });

    test('toMap incluye todas las columnas necesarias', () {
      final cfg = ConfigModel.defaults().copyWith(nombreImpresora: 'POS-80C');
      final map = cfg.toMap();

      expect(map['nombre_impresora'], 'POS-80C');
      expect(map['id'], 1);
      for (final col in [
        'precio_adulto_lun', 'precio_adulto_mar', 'precio_adulto_mie',
        'precio_adulto_jue', 'precio_adulto_vie', 'precio_adulto_sab', 'precio_adulto_dom',
        'precio_nino_lun',   'precio_nino_mar',   'precio_nino_mie',
        'precio_nino_jue',   'precio_nino_vie',   'precio_nino_sab',   'precio_nino_dom',
      ]) {
        expect(map.containsKey(col), true, reason: 'falta columna: $col');
      }
    });

    test('fromMap → toMap roundtrip conserva todos los valores', () {
      final original = ConfigModel.defaults().copyWith(nombreImpresora: 'TEST');
      final recovered = ConfigModel.fromMap(original.toMap());

      expect(recovered.nombreImpresora, original.nombreImpresora);
      expect(recovered.preciosAdulto, original.preciosAdulto);
      expect(recovered.preciosNino, original.preciosNino);
    });
  });
}
