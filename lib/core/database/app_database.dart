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
      version: 1,
      onCreate: _onCreate,
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

    await db.execute('''
      CREATE TABLE configuracion (
        id                   INTEGER PRIMARY KEY CHECK (id = 1),
        precio_adulto_semana REAL NOT NULL DEFAULT 8.0,
        precio_adulto_finde  REAL NOT NULL DEFAULT 10.0,
        precio_nino_semana   REAL NOT NULL DEFAULT 5.0,
        precio_nino_finde    REAL NOT NULL DEFAULT 7.0,
        nombre_impresora     TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Fila única de configuración
    await db.insert('configuracion', {
      'id': 1,
      'precio_adulto_semana': 8.0,
      'precio_adulto_finde': 10.0,
      'precio_nino_semana': 5.0,
      'precio_nino_finde': 7.0,
      'nombre_impresora': '',
    });
  }
}
