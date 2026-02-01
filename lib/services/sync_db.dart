import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/internal_db.dart';
import '../models/job.dart';

class SyncDb {
  static const String apiKey = 'api_warehouse_student_key_1234567890abcdef';

  static Map<String, String> h() {
    return {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey
    };
  }

  static Future<void> syncUsersAndJobs({
    http.Client? client,
    String baseUrl = 'http://localhost:5000'
  }) async {
    final c = client ?? http.Client();
    try {
      await syncUsers(client: c, baseUrl: baseUrl).timeout(const Duration(seconds: 120));
      await syncJobs(client: c, baseUrl: baseUrl).timeout(const Duration(seconds: 120));
    } finally {
      if (client == null) {
        c.close();
      }
    }
  }

  static Future<void> syncUsers({
    required http.Client client,
    required String baseUrl
  }) async {
    List<String> names = await DatabaseHelper.getAllUsernames();

    final response = await client.post(
      Uri.parse('$baseUrl/sync/users'),
      headers: h(),
      body: jsonEncode({'users': names})
    );

    if (response.statusCode != 200) {
      throw 'users ${response.statusCode}';
    }
  }

  static Future<void> syncJobs({
    required http.Client client,
    required String baseUrl
  }) async {
    List<Job> list = await DatabaseHelper.getUnsyncedJobs();

    for (final j in list) {
      final res = await client.post(
        Uri.parse('$baseUrl/sync/jobs'),
        headers: h(),
        body: jsonEncode({
          'jobNumber': j.jobNumber,
          'aircraft': j.aircraft,
          'description': j.description,
          'status': j.status
        })
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        int sid = data['id'] as int;
        await DatabaseHelper.markJobSynced(j.id!, sid);
      } else {
        throw 'jobs ${res.statusCode}';
      }
    }
  }
}
