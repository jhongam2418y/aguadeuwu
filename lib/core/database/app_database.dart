import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;
  // Completer usado para serializar llamadas concurrentes durante la init.
  static Completer<Database>? _initCompleter;

  /// Devuelve la instancia de la base de datos.
  /// Si ya está abierta la retorna de inmediato.
  /// Si está en proceso de apertura, todos los llamantes esperan al mismo
  /// Completer (no se abre la BD dos veces en paralelo).
  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<Database>();
    try {
      _db = await _initDatabase();
      _initCompleter!.complete(_db);
    } catch (e, st) {
      final c = _initCompleter!;
      _initCompleter = null; // permite reintentar en el próximo acceso
      c.completeError(e, st);
      rethrow;
    }
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // LOCALAPPDATA apunta a C:\Users\<usuario>\AppData\Local en todas las
    // versiones de Windows.  Está disponible en producción (.exe) y
    // sobrevive a desinstalaciones que no limpien AppData\Local.
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      throw StateError(
          '[AppDatabase] LOCALAPPDATA no está definida. '
          'Asegúrate de ejecutar la app como usuario normal (no como SYSTEM).');
    }

    // Construir la ruta del directorio de datos.
    final dbDir = Directory(join(localAppData, 'Piscigranja'));

    try {
      // Crea la carpeta si no existe. recursive: true no lanza error si ya existe.
      await dbDir.create(recursive: true);
    } on PathAccessException catch (e) {
      throw StateError(
          '[AppDatabase] Sin permisos para crear el directorio ${dbDir.path}: $e');
    }

    final dbPath = join(dbDir.path, 'piscigranja.db');

    try {
      return await openDatabase(
        dbPath,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw StateError(
          '[AppDatabase] No se pudo abrir la base de datos en $dbPath: $e');
    }
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
        hora      TEXT    NOT NULL,
        anulado   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_tickets_hora ON tickets(hora)');

    await _crearTablaConfiguracion(db);
    await _insertarConfigDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final rows = await db.query('configuracion', where: 'id = 1');
      final impresora = rows.isNotEmpty ? (rows.first['nombre_impresora'] as String? ?? '') : '';

      await db.execute('DROP TABLE IF EXISTS configuracion');
      await _crearTablaConfiguracion(db);
      await _insertarConfigDefaults(db, nombreImpresora: impresora);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tickets ADD COLUMN anulado INTEGER NOT NULL DEFAULT 0');
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
      'precio_adulto_lun': 5.0, 'precio_adulto_mar': 5.0,
      'precio_adulto_mie': 5.0, 'precio_adulto_jue': 5.0,
      'precio_adulto_vie': 5.0, 'precio_adulto_sab': 7.0,
      'precio_adulto_dom': 7.0,
      'precio_nino_lun': 2.50, 'precio_nino_mar': 2.50,
      'precio_nino_mie': 2.50, 'precio_nino_jue': 2.50,
      'precio_nino_vie': 2.50, 'precio_nino_sab': 5.0,
      'precio_nino_dom': 5.0,
      'nombre_impresora': nombreImpresora,
    });
  }

  // ─── Backup / Restauración ───────────────────────────────────────────────

  /// Ruta absoluta del archivo de base de datos activo.
  Future<String> get dbFilePath async {
    final localAppData = Platform.environment['LOCALAPPDATA']!;
    return join(localAppData, 'Piscigranja', 'piscigranja.db');
  }

  /// Copia la BD activa al archivo [destino].
  /// Llama a [database] primero para garantizar que todos los cambios estén
  /// escritos en disco (SQLite hace checkpoint al cerrar la WAL).
  Future<void> exportarBackup(String destino) async {
    await database; // asegura que la BD esté abierta y actualizada
    final src = await dbFilePath;
    await File(src).copy(destino);
  }

  /// Restaura la BD desde [origen].
  /// Cierra la conexión actual, reemplaza el archivo y permite que la
  /// próxima llamada a [database] la vuelva a abrir desde cero.
  Future<void> restaurarBackup(String origen) async {
    final dest = await dbFilePath;
    await _db?.close();
    _db = null;
    _initCompleter = null;
    await File(origen).copy(dest);
  }

}
