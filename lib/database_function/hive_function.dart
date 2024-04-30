import 'package:csv_read/database_function/hive_model.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static const _dbVersion =3;

  Database? _db;
  DatabaseHelper._internal();

  Future<Database?> get db async {

    return _db??await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/companies.db';

    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Placeholder table creation (replace with your actual schema)
        await db.execute('''
          CREATE TABLE companies (
            companyName TEXT PRIMARY KEY,
            companyDetails TEXT,
            directorDetails TEXT
          )
        ''');
      },
    );
    return database;
  }

  // CRUD operations with dynamic table name

  Future<void> insertCompany(String tableName, Company company) async {
    final db = await this.db;

    // Check if table exists before inserting
    if (!await _hasTable(tableName)) {
      await _createTable(tableName);
    }

    await db!.insert(tableName.replaceAll(' ', '_'), company.toMap());
  }

  Future<Company?> getCompany(String tableName, String companyName) async {
    final db = await this.db;
    final maps = await db!.query(
      tableName.replaceAll(' ', '_'),
      where: 'companyName = ?',
      whereArgs: [companyName],
    );

    if (maps.isNotEmpty) {
      return Company.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateCompany(String tableName, Company company) async {
    final db = await this.db;
    return await db!.update(
      tableName.replaceAll(' ', '_'),
      company.toMap(),
      where: 'companyName = ?',
      whereArgs: [company.companyName],
    );
  }

  Future<int> deleteCompany(String tableName, String companyName) async {
    final db = await this.db;
    return await db!.delete(
      tableName.replaceAll(' ', '_'),
      where: 'companyName = ?',
      whereArgs: [companyName],
    );
  }

  // Helper methods for table management

  Future<bool> _hasTable(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> tables = await db!.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='${tableName.replaceAll(' ', '_')}'",
    );
    return tables.isNotEmpty;
  }

  Future<void> _createTable(String tableName) async {
    final db = await this.db;
    // Replace with your actual CREATE TABLE statement based on your data model
    await db!.execute('''
      CREATE TABLE ${tableName.replaceAll(' ', '_')} (
        companyName TEXT PRIMARY KEY,
        companyDetails TEXT,
        directorDetails TEXT
      )
    ''');
  }

  Future<void> deleteTableData({required String tableName}) async {

    final db  = await this.db;

    await db!.execute(
      '''
      DELETE FROM ${tableName.replaceAll(' ', '_')};
      
      '''

    );
  }
}
