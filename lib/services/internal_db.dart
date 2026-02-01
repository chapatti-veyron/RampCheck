import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/job.dart';
import '../models/inspection_item.dart';
import '../models/attachment.dart';

class DatabaseHelper {
  static Database? database;

  static Future<Database> getDatabase() async {
    if (database != null) return database!;

    String base = await getDatabasesPath();
    String path = join(base, 'rampcheck.db');

    database = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');

        await db.execute('''
          CREATE TABLE jobs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jobNumber TEXT NOT NULL,
            aircraft TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'pending',
            synced INTEGER DEFAULT 0,
            serverId INTEGER,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE inspection_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jobId INTEGER NOT NULL,
            componentName TEXT NOT NULL,
            description TEXT NOT NULL,
            result TEXT DEFAULT 'NOT_INSPECTED',
            notes TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY(jobId) REFERENCES jobs(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE attachments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspectionItemId INTEGER NOT NULL,
            fileName TEXT NOT NULL,
            filePath TEXT NOT NULL,
            fileSize INTEGER NOT NULL,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY(inspectionItemId) REFERENCES inspection_items(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL,
            salt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE audit_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            entity TEXT NOT NULL,
            entityId INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');

        await _seedUser(db, 'user1', 'securepass');
      },
      
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      }
    );

    return database!;
  }

  static Future<void> _seedUser(Database db, String username, String password) async {
    final existing = await db.query('users', where: 'username = ?', whereArgs: [username], limit: 1);
    if (existing.isNotEmpty) return;

    final salt = _makeSalt();
    final hash = _hashPassword(password, salt);

    await db.insert('users', {
      'username': username,
      'passwordHash': hash,
      'salt': salt
    });
  }

  static String _makeSalt() {
    final r = Random();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final data = utf8.encode('$salt|$password');
    return sha256.convert(data).toString();
  }

  static Future<void> log(String action, String entity, int id) async {
    final db = await getDatabase();
    await db.insert('audit_log', {
      'action': action,
      'entity': entity,
      'entityId': id,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  static Future<bool> authenticateUser(String username, String password) async {
    final db = await getDatabase();

    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1
    );

    if (rows.isEmpty) return false;

    final salt = rows[0]['salt'] as String;
    final storedHash = rows[0]['passwordHash'] as String;
    final incomingHash = _hashPassword(password, salt);

    return storedHash == incomingHash;
  }

  static Future<List<String>> getAllUsernames() async {
    final db = await getDatabase();
    final rows = await db.query('users', columns: ['username'], orderBy: 'username ASC');
    List<String> out = [];
    for (final r in rows) {
      out.add(r['username'] as String);
    }
    return out;
  }

  static Future<int> addJob(Job job) async {
    final db = await getDatabase();
    final map = job.toMap();
    map['createdAt'] = DateTime.now().toIso8601String();

    final id = await db.insert('jobs', map);
    await log('ADD', 'job', id);
    return id;
  }

  static Future<void> updateJob(Job job) async {
    final db = await getDatabase();
    await db.update('jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
    await log('UPDATE', 'job', job.id!);
  }

  static Future<List<Job>> getAllJobs() async {
    final db = await getDatabase();
    final maps = await db.query('jobs', orderBy: 'id DESC');
    return maps.map((m) => Job.fromMap(m)).toList();
  }

  static Future<List<Job>> getUnsyncedJobs() async {
    final db = await getDatabase();
    final maps = await db.query('jobs', where: 'synced = ?', whereArgs: [0], orderBy: 'id ASC');
    return maps.map((m) => Job.fromMap(m)).toList();
  }

  static Future<void> markJobSynced(int localId, int serverId) async {
    final db = await getDatabase();
    await db.update(
      'jobs',
      {'synced': 1, 'serverId': serverId},
      where: 'id = ?',
      whereArgs: [localId]
    );
    await log('UPDATE', 'job', localId);
  }

  static Future<int> addInspectionItem(InspectionItem item) async {
    final db = await getDatabase();
    final id = await db.insert('inspection_items', item.toMap());
    await log('ADD', 'inspection_item', id);
    return id;
  }

  static Future<void> updateInspectionItem(InspectionItem item) async {
    final db = await getDatabase();
    await db.update('inspection_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    await log('UPDATE', 'inspection_item', item.id!);
  }

  static Future<List<InspectionItem>> getInspectionItemsForJob(int jobId) async {
    final db = await getDatabase();
    final maps = await db.query('inspection_items', where: 'jobId = ?', whereArgs: [jobId], orderBy: 'componentName ASC');
    return maps.map((m) => InspectionItem.fromMap(m)).toList();
  }

  static Future<int> addAttachment(Attachment a) async {
    final db = await getDatabase();
    final id = await db.insert('attachments', a.toMap());
    await log('ADD', 'attachment', id);
    return id;
  }

  static Future<void> deleteAttachment(int id) async {
    final db = await getDatabase();
    await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
    await log('DELETE', 'attachment', id);
  }

  static Future<List<Attachment>> getAttachmentsForInspectionItem(int inspectionItemId) async {
    final db = await getDatabase();
    final maps = await db.query(
      'attachments',
      where: 'inspectionItemId = ?',
      whereArgs: [inspectionItemId],
      orderBy: 'id ASC'
    );
    return maps.map((m) => Attachment.fromMap(m)).toList();
  }

  static Future<int> runRetention() async {
    final db = await getDatabase();
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final deleted = await db.delete(
      'jobs',
      where: 'status = ? AND createdAt < ?',
      whereArgs: ['completed', cutoff]
    );

    if (deleted > 0) {
      await log('RETENTION', 'job', deleted);
    }

    return deleted;
  }
}
