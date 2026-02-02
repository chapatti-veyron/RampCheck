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

    List<Job> list = await InternalDB.getAllJobs();

    setState(() {
      jobs = list;
      loading = false;
    });
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

    await InternalDB.updateJob(x);
    await load();
  }

  void addDialog() {
    TextEditingController jobNum = TextEditingController();
    TextEditingController aircraft = TextEditingController();
    TextEditingController desc = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Job'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: jobNum,
                  decoration: const InputDecoration(
                    labelText: 'Job Number',
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aircraft,
                  decoration: const InputDecoration(
                    labelText: 'Aircraft',
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desc,
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
                String jn = jobNum.text.trim();
                String ac = aircraft.text.trim();

                if (jn.isEmpty || ac.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job number and aircraft required'))
                  );
                  return;
                }

                Job job = Job(
                  jobNumber: jn,
                  aircraft: ac,
                  description: desc.text.trim(),
                  status: 'pending',
                  synced: 0
                );

                await InternalDB.addJob(job);
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
          SnackBar(content: Text('Sync failed'))
        );
      }
    }

    setState(() {
      syncing = false;
    });
  }

  Widget card(Job j) {
    Icon syncIcon;
    if (j.synced == 1) {
      syncIcon = const Icon(Icons.cloud_done, size: 20, color: Colors.green);
    } else {
      syncIcon = const Icon(Icons.cloud_off, size: 20, color: Colors.orange);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        color: Colors.white
      ),
      child: Column(
        children: [
          ListTile(
            leading: syncIcon,
            title: Text(j.jobNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${j.aircraft} - ${j.status.toUpperCase()}'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobDetailScreen(job: j))
              );
              await load();
            }
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setStatus(j, 'pending'),
                    child: const Text('Pending', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setStatus(j, 'in_progress'),
                    child: const Text('In Progress', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setStatus(j, 'completed'),
                    child: const Text('Completed', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: syncing ? null : doSync,
            icon: const Icon(Icons.sync),
            color: Colors.white,
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