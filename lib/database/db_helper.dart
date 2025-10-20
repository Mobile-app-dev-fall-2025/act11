import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  static const _dbName = 'vehicle_maintenance.db';
  static const _dbVersion = 1;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE folders(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    suit TEXT
  )
''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        value INTEGER,
        suit TEXT,
        image TEXT,
        folder_id INTEGER,
        FOREIGN KEY (foler_id) REFERENCES folders(id)
      )
    ''');
  }

  // ===== CRUD HELPERS =====

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future close() async {
    final db = await database;
    db.close();
  }

  // ===== EXTRA UTILITIES =====

  // Preload suits
  Future<void> seedFolders() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM folders'),
    );
    if (count == 0) {
      final suitList = [
        {'suit': 'Hearts'},
        {'suit': 'Spades'},
        {'suit': 'Diamonds'},
        {'suit': 'Clubs'},
      ];

      for (var item in suitList) {
        await db.insert('folders', item);
      }
    }
  }
}
