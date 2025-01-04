import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gym_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        daysLeft TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertUser(String username, String password) async {
    final db = await database;
    return await db.insert('users', {'username': username, 'password': password});
  }

  Future<Map<String, String>?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return {'username': maps.first['username'], 'password': maps.first['password']};
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> deleteUser(String username) async {
    final db = await database;
    int result = await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    await getUsers(); // Update the user list in real-time
    return result;
  }

  Future<int> insertPerson(String name, String paymentDate, String daysLeft) async {
    final db = await database;
    return await db.insert('people', {'name': name, 'paymentDate': paymentDate, 'daysLeft': daysLeft});
  }

  Future<List<Map<String, dynamic>>> getPeople() async {
    final db = await database;
    return await db.query('people');
  }

  Future<int> updatePerson(int id, String name, String paymentDate, String daysLeft) async {
    final db = await database;
    return await db.update(
      'people',
      {'name': name, 'paymentDate': paymentDate, 'daysLeft': daysLeft},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    return await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
