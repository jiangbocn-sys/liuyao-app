import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// 数据库初始化帮助类
/// 单表设计：divination_records
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// 数据库名称
  static const String _databaseName = 'liuyao_records.db';

  /// 数据库版本（升级到版本2，修复列名问题）
  static const int _databaseVersion = 2;

  /// 表名
  static const String tableRecords = 'divination_records';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表（使用驼峰命名，与旧版本兼容）
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        createdAt TEXT NOT NULL,
        divTime TEXT NOT NULL,
        querentName TEXT NOT NULL DEFAULT '',
        querentGender TEXT NOT NULL DEFAULT '',
        question TEXT NOT NULL DEFAULT '',
        startMethod TEXT NOT NULL DEFAULT 'manual',
        lunarYear TEXT,
        lunarMonth TEXT,
        lunarDay TEXT,
        yearGz TEXT NOT NULL,
        monthGz TEXT NOT NULL,
        dayGz TEXT NOT NULL,
        hourGz TEXT NOT NULL,
        xunKong TEXT NOT NULL,
        benGua TEXT NOT NULL,
        bianGua TEXT,
        huGua TEXT,
        backCounts TEXT NOT NULL,
        yaoLines TEXT NOT NULL,
        shensha TEXT NOT NULL,
        interpretation TEXT,
        tags TEXT,
        updatedAt TEXT
      )
    ''');
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 版本1到版本2：重建表以修复列名问题
      await db.execute('DROP TABLE IF EXISTS $tableRecords');
      await _onCreate(db, newVersion);
    }
  }

  /// 清空所有记录（用于测试）
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableRecords);
  }

  /// 删除数据库（用于测试）
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}