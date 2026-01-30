import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/internal_db.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Job> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllJobs();
  }

  void loadAllJobs() async {
    setState(() {
      isLoading = true;
    });

    List<Job> allJobs = await DatabaseHelper.getAllJobs();

    setState(() {
      jobs = allJobs;
      isLoading = false;
    });
  }

  String formatStatus(String status) {
    if (status == 'in_progress') return 'IN PROGRESS';
    if (status == 'completed') return 'COMPLETED';
    return 'PENDING';
  }

  Future<void> updateJobStatus(Job job, String newStatus) async {
    Job updated = Job(
      id: job.id,
      jobNumber: job.jobNumber,
      aircraft: job.aircraft,
      description: job.description,
      status: newStatus,
      synced: 0
    );

    await DatabaseHelper.updateJob(updated);
    loadAllJobs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job status updated to ${formatStatus(newStatus)}'))
    );
  }

  void showAddJobDialog() {
    final jobNumberController = TextEditingController();
    final aircraftController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Job'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jobNumberController,
                  decoration: const InputDecoration(labelText: 'Job Number')
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aircraftController,
                  decoration: const InputDecoration(labelText: 'Aircraft Registration')
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2
                )
              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                if (jobNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job number is required'))
                  );
                  return;
                }

                if (aircraftController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aircraft is required'))
                  );
                  return;
                }

                Job newJob = Job(
                  jobNumber: jobNumberController.text,
                  aircraft: aircraftController.text,
                  description: descriptionController.text,
                  status: 'pending',
                  synced: 0
                );

                await DatabaseHelper.addJob(newJob);
                Navigator.pop(context);
                loadAllJobs();
              },
              child: const Text('Save')
            )
          ]
        );
      }
    );
  }

  void navigateToJobDetail(Job job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job))
    );
    loadAllJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Jobs')
      ),
      body: buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddJobDialog,
        label: const Text('New Job')
      )
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs.isEmpty) {
      return const Center(
        child: Text('No jobs added yet', style: TextStyle(color: Colors.black54))
      );
    }

    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return buildJobCard(jobs[index]);
      }
    );
  }

  Widget buildStatusBox(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        color: Colors.white
      ),
      child: Text(
        formatStatus(status),
        style: const TextStyle(fontSize: 12, color: Colors.black87)
      )
    );
  }

  Widget buildJobCard(Job job) {
    return Card(
      child: ListTile(
        title: Text(
          job.jobNumber,
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text(job.aircraft),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildStatusBox(job.status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                updateJobStatus(job, value);
              },
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
        onTap: () {
          navigateToJobDetail(job);
        }
      )
    );
  }
}
