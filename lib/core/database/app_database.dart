import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'piscigranja.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL,
        adultos   INTEGER NOT NULL,
        ninos     INTEGER NOT NULL,
        monto     REAL    NOT NULL,
        metodo_pago TEXT  NOT NULL DEFAULT 'efectivo',
        hora      TEXT    NOT NULL
      )
    ''');

    await _crearTablaConfiguracion(db);
    await _insertarConfigDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Leer impresora antes de borrar
      final rows = await db.query('configuracion', where: 'id = 1');
      final impresora = rows.isNotEmpty ? (rows.first['nombre_impresora'] as String? ?? '') : '';

      await db.execute('DROP TABLE IF EXISTS configuracion');
      await _crearTablaConfiguracion(db);
      await _insertarConfigDefaults(db, nombreImpresora: impresora);
    }
  }

  Future<void> _crearTablaConfiguracion(Database db) async {
    await db.execute('''
      CREATE TABLE configuracion (
        id                  INTEGER PRIMARY KEY CHECK (id = 1),
        precio_adulto_lun   REAL NOT NULL DEFAULT 8.0,
        precio_adulto_mar   REAL NOT NULL DEFAULT 8.0,
        precio_adulto_mie   REAL NOT NULL DEFAULT 8.0,
        precio_adulto_jue   REAL NOT NULL DEFAULT 8.0,
        precio_adulto_vie   REAL NOT NULL DEFAULT 8.0,
        precio_adulto_sab   REAL NOT NULL DEFAULT 10.0,
        precio_adulto_dom   REAL NOT NULL DEFAULT 10.0,
        precio_nino_lun     REAL NOT NULL DEFAULT 5.0,
        precio_nino_mar     REAL NOT NULL DEFAULT 5.0,
        precio_nino_mie     REAL NOT NULL DEFAULT 5.0,
        precio_nino_jue     REAL NOT NULL DEFAULT 5.0,
        precio_nino_vie     REAL NOT NULL DEFAULT 5.0,
        precio_nino_sab     REAL NOT NULL DEFAULT 7.0,
        precio_nino_dom     REAL NOT NULL DEFAULT 7.0,
        nombre_impresora    TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _insertarConfigDefaults(Database db, {String nombreImpresora = ''}) async {
    await db.insert('configuracion', {
      'id': 1,
      'precio_adulto_lun': 8.0, 'precio_adulto_mar': 8.0,
      'precio_adulto_mie': 8.0, 'precio_adulto_jue': 8.0,
      'precio_adulto_vie': 8.0, 'precio_adulto_sab': 10.0,
      'precio_adulto_dom': 10.0,
      'precio_nino_lun': 5.0, 'precio_nino_mar': 5.0,
      'precio_nino_mie': 5.0, 'precio_nino_jue': 5.0,
      'precio_nino_vie': 5.0, 'precio_nino_sab': 7.0,
      'precio_nino_dom': 7.0,
      'nombre_impresora': nombreImpresora,
    });
  }
}
