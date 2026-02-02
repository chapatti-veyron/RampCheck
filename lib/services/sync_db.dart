import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/internal_db.dart';
import '../models/job.dart';

class SyncDb {
  static const String apiKey = 'api_warehouse_student_key_1234567890abcdef';

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey
    };
  }

  static Future<void> syncUsersAndJobs({
    http.Client? client,
    String baseUrl = 'http://localhost:5000'
  }) async {
    final httpClient = client ?? http.Client();
    
    try {
      await syncUsers(client: httpClient, baseUrl: baseUrl);
      await syncJobs(client: httpClient, baseUrl: baseUrl);
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  static Future<void> syncUsers({
    required http.Client client,
    required String baseUrl
  }) async {
    List<String> usernames = await DatabaseHelper.getAllUsernames();

    final response = await client.post(
      Uri.parse('$baseUrl/sync/users'),
      headers: getHeaders(),
      body: jsonEncode({'users': usernames})
    );

    if (response.statusCode != 200) {
      throw Exception('User sync failed: ${response.statusCode}');
    }
  }

  static Future<void> syncJobs({
    required http.Client client,
    required String baseUrl
  }) async {
    List<Job> unsyncedJobs = await DatabaseHelper.getUnsyncedJobs();

    for (final job in unsyncedJobs) {
      final response = await client.post(
        Uri.parse('$baseUrl/sync/jobs'),
        headers: getHeaders(),
        body: jsonEncode({
          'jobNumber': job.jobNumber,
          'aircraft': job.aircraft,
          'description': job.description,
          'status': job.status
        })
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        int serverId = data['id'] as int;
        await DatabaseHelper.markJobSynced(job.id!, serverId);
      } else {
        throw Exception('Job sync failed: ${response.statusCode}');
      }
    }
  }
}