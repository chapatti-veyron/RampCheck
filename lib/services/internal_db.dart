import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/job.dart';
import '../models/inspection_item.dart';
import '../models/attachment.dart';

class DatabaseHelper {
  static Database? database;

  static Future<Database> getDatabase() async {
    if (database != null) {
      return database!;
    }

    String path = join(await getDatabasesPath(), 'rampcheck.db');

    database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jobNumber TEXT NOT NULL,
            aircraft TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            synced INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE inspection_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jobId INTEGER NOT NULL,
            componentName TEXT NOT NULL,
            description TEXT NOT NULL,
            result TEXT NOT NULL,
            notes TEXT,
            synced INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspectionItemId INTEGER NOT NULL,
            fileName TEXT NOT NULL,
            filePath TEXT NOT NULL,
            fileSize INTEGER NOT NULL,
            synced INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

        await db.insert('users', {
          'username': 'user1',
          'password': 'securepass'
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL
            )
          ''');

          List<Map<String, dynamic>> existing = await db.query(
            'users',
            where: 'username = ?',
            whereArgs: ['user1'],
            limit: 1
          );

          if (existing.isEmpty) {
            await db.insert('users', {
              'username': 'user1',
              'password': 'securepass'
            });
          }
        }
      }
    );

    return database!;
  }

  static Future<bool> authenticateUser(String username, String password) async {
    final db = await getDatabase();

    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1
    );

    return rows.isNotEmpty;
  }

  static Future<int> insertJob(Job job) async {
    final db = await getDatabase();
    return await db.insert('jobs', job.toMap());
  }

  static Future<int> addJob(Job job) async {
    return insertJob(job);
  }

  static Future<List<Job>> getAllJobs() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('jobs', orderBy: 'id DESC');

    return List.generate(maps.length, (i) {
      return Job.fromMap(maps[i]);
    });
  }

  static Future<int> updateJob(Job job) async {
    final db = await getDatabase();
    return await db.update(
      'jobs',
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id]
    );
  }

  static Future<int> deleteJob(int id) async {
    final db = await getDatabase();
    return await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  static Future<int> insertInspectionItem(InspectionItem item) async {
    final db = await getDatabase();
    return await db.insert('inspection_items', item.toMap());
  }

  static Future<int> addInspectionItem(InspectionItem item) async {
    return insertInspectionItem(item);
  }

  static Future<List<InspectionItem>> getInspectionItemsForJob(int jobId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'inspection_items',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'componentName ASC'
    );

    return List.generate(maps.length, (i) {
      return InspectionItem.fromMap(maps[i]);
    });
  }

  static Future<int> updateInspectionItem(InspectionItem item) async {
    final db = await getDatabase();
    return await db.update(
      'inspection_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id]
    );
  }

  static Future<int> deleteInspectionItem(int id) async {
    final db = await getDatabase();
    return await db.delete(
      'inspection_items',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  static Future<int> insertAttachment(Attachment attachment) async {
    final db = await getDatabase();
    return await db.insert('attachments', attachment.toMap());
  }

  static Future<int> addAttachment(Attachment attachment) async {
    return insertAttachment(attachment);
  }

  static Future<List<Attachment>> getAttachmentsForInspectionItem(int inspectionItemId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'inspectionItemId = ?',
      whereArgs: [inspectionItemId],
      orderBy: 'id DESC'
    );

    return List.generate(maps.length, (i) {
      return Attachment.fromMap(maps[i]);
    });
  }

  static Future<int> deleteAttachment(int id) async {
    final db = await getDatabase();
    return await db.delete(
      'attachments',
      where: 'id = ?',
      whereArgs: [id]
    );
  }
}
