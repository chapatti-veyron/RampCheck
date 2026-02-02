import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/services/internal_db.dart';
import '../lib/models/job.dart';
import '../lib/services/sync_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('UT-001: Verify audit log entry added with ADD and JOB parameters', () async {
    await DatabaseHelper.getDatabase();

    final sw = Stopwatch()..start();
    
    await DatabaseHelper.addJob(Job(
      jobNumber: 'testnum',
      aircraft: 'testcraft',
      description: 'Test audit logging',
      status: 'pending',
      synced: 0
    ));

    sw.stop();

    final db = await DatabaseHelper.getDatabase();
    final auditEntries = await db.query(
      'audit_log',
      where: 'action = ? AND entity = ?',
      whereArgs: ['ADD', 'job']
    );

    expect(auditEntries.isNotEmpty, true);
    expect(sw.elapsedMilliseconds < 300, true);
  });

  test('UT-002: Verify UI response time under 300ms', () async {
    await DatabaseHelper.getDatabase();

    await DatabaseHelper.addJob(Job(
      jobNumber: 'testnum',
      aircraft: 'testcraft',
      description: 'Test audit logging',
      status: 'pending',
      synced: 0
    ));

    final sw = Stopwatch()..start();
    await DatabaseHelper.getAllJobs();
    sw.stop();

    expect(sw.elapsedMilliseconds < 300, true);
  });

  test('UT-003: Verify server sync under 120s', () async {
    await DatabaseHelper.getDatabase();

    await DatabaseHelper.addJob(Job(
      jobNumber: 'testnum',
      aircraft: 'testcraft',
      description: 'Test audit logging',
      status: 'pending',
      synced: 0
    ));

    final client = MockClient((req) async {
      if (req.url.path.endsWith('/sync/users')) {
        return http.Response('{"added":1,"total":1}', 200);
      }
      if (req.url.path.endsWith('/sync/jobs')) {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{"id":1}', 201);
      }
      return http.Response('not found', 404);
    });

    final sw = Stopwatch()..start();
    await SyncDb.syncUsersAndJobs(client: client, baseUrl: 'http://test');
    sw.stop();

    expect(sw.elapsed.inSeconds < 120, true);
    
    final db = await DatabaseHelper.getDatabase();
    final syncedJobs = await db.query(
      'jobs',
      where: 'synced = ? AND serverId IS NOT NULL',
      whereArgs: [1]
    );

    expect(syncedJobs.isNotEmpty, true);
  });
}