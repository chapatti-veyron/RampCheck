import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/sync_db.dart';
import '../services/internal_db.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Job> jobs = [];
  bool loading = true;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
    });

    List<Job> list = await DatabaseHelper.getAllJobs();

    setState(() {
      jobs = list;
      loading = false;
    });
  }

  String s(String v) {
    if (v == 'in_progress') return 'IN PROGRESS';
    if (v == 'completed') return 'COMPLETED';
    return 'PENDING';
  }

  Future<void> setStatus(Job j, String v) async {
    Job x = Job(
      id: j.id,
      serverId: j.serverId,
      jobNumber: j.jobNumber,
      aircraft: j.aircraft,
      description: j.description,
      status: v,
      synced: 0
    );

    await DatabaseHelper.updateJob(x);
    await load();
  }

  void addDialog() {
    TextEditingController a = TextEditingController();
    TextEditingController b = TextEditingController();
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Job'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: a,
                  decoration: const InputDecoration(
                    labelText: 'Job Number',
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: b,
                  decoration: const InputDecoration(
                    labelText: 'Aircraft',
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder()
                  )
                )
              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                String jn = a.text.trim();
                String ac = b.text.trim();

                if (jn.isEmpty || ac.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job number and aircraft are required'))
                  );
                  return;
                }

                Job job = Job(
                  jobNumber: jn,
                  aircraft: ac,
                  description: c.text.trim(),
                  status: 'pending',
                  synced: 0
                );

                await DatabaseHelper.addJob(job);
                Navigator.pop(context);
                await load();
              },
              child: const Text('Save')
            )
          ]
        );
      }
    );
  }

  Future<void> doSync() async {
    setState(() {
      syncing = true;
    });

    try {
      await SyncDb.syncUsersAndJobs();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'))
        );
      }
    }

    setState(() {
      syncing = false;
    });
  }

  Widget box(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        color: Colors.white
      ),
      child: Text(t, style: const TextStyle(fontSize: 12))
    );
  }

  Widget card(Job j) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        color: Colors.white
      ),
      child: ListTile(
        title: Text(j.jobNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(j.aircraft),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box(s(j.status)),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) => setStatus(j, v),
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(value: 'pending', child: Text('Set Pending')),
                  PopupMenuItem(value: 'in_progress', child: Text('Set In Progress')),
                  PopupMenuItem(value: 'completed', child: Text('Set Completed'))
                ];
              }
            )
          ]
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailScreen(job: j))
          );
          await load();
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          TextButton(
            onPressed: syncing ? null : doSync,
            child: Text(syncing ? 'Syncing...' : 'Sync', style: const TextStyle(color: Colors.white))
          )
        ]
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? const Center(child: Text('No jobs'))
              : ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, i) => card(jobs[i])
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addDialog,
        label: const Text('New Job')
      )
    );
  }
}
