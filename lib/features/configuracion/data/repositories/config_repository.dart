import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/config_model.dart';

class ConfigRepository {
  ConfigRepository._();
  static final ConfigRepository instance = ConfigRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  Future<ConfigModel> cargar() async {
    final db = await _db;
    final rows = await db.query('configuracion', where: 'id = 1');
    if (rows.isEmpty) return ConfigModel.defaults();
    return ConfigModel.fromMap(rows.first);
  }

  Future<void> guardar(ConfigModel config) async {
    final db = await _db;
    await db.insert(
      'configuracion',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
