import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/job.dart';
import '../models/inspection_item.dart';
import '../models/attachment.dart';
import '../services/internal_db.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  List<InspectionItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    setState(() {
      isLoading = true;
    });

    List<InspectionItem> allItems = await DatabaseHelper.getInspectionItemsForJob(widget.job.id!);

    setState(() {
      items = allItems;
      isLoading = false;
    });
  }

  String formatJobStatus(String status) {
    if (status == 'in_progress') return 'IN PROGRESS';
    if (status == 'completed') return 'COMPLETED';
    return 'PENDING';
  }

  Future<void> updateJobStatus(String newStatus) async {
    Job updatedJob = Job(
      id: widget.job.id,
      jobNumber: widget.job.jobNumber,
      aircraft: widget.job.aircraft,
      description: widget.job.description,
      status: newStatus,
      synced: 0
    );

    await DatabaseHelper.updateJob(updatedJob);

    setState(() {
      widget.job.status = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to ${formatJobStatus(newStatus)}'))
    );
  }

  void showAddItemDialog() {
    final componentController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Inspection Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: componentController,
                decoration: const InputDecoration(
                  labelText: 'Component Name',
                  hintText: 'e.g. Landing Gear'
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2
              )
            ]
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
                if (componentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Component name is required'))
                  );
                  return;
                }

                InspectionItem newItem = InspectionItem(
                  jobId: widget.job.id!,
                  componentName: componentController.text,
                  description: descriptionController.text,
                  result: 'NOT_INSPECTED',
                  synced: 0
                );

                await DatabaseHelper.addInspectionItem(newItem);
                Navigator.pop(context);
                loadItems();
              },
              child: const Text('Save')
            )
          ]
        );
      }
    );
  }

  void showEditItemDialog(InspectionItem item) async {
    String selectedResult = item.result;
    List<Attachment> attachments = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> refreshAttachments() async {
              List<Attachment> updated = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);
              setDialogState(() {
                attachments = updated;
              });
            }

            return AlertDialog(
              title: Text(item.componentName),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedResult,
                      decoration: const InputDecoration(labelText: 'Result'),
                      items: const [
                        DropdownMenuItem(value: 'NOT_INSPECTED', child: Text('Not inspected')),
                        DropdownMenuItem(value: 'PASS', child: Text('Pass')),
                        DropdownMenuItem(value: 'FAIL', child: Text('Fail')),
                        DropdownMenuItem(value: 'N_A', child: Text('N/A'))
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedResult = value;
                        });
                      }
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Attachments', style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(height: 8),
                    if (attachments.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('None', style: TextStyle(color: Colors.black54))
                      )
                    else
                      Column(
                        children: attachments.map((attachment) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              color: Colors.white
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(attachment.fileName, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text('${(attachment.fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11, color: Colors.black54))
                                    ]
                                  )
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await DatabaseHelper.deleteAttachment(attachment.id!);
                                    await refreshAttachments();
                                  },
                                  child: const Text('Remove')
                                )
                              ]
                            )
                          );
                        }).toList()
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);

                          if (result == null) return;
                          if (result.files.isEmpty) return;
                          if (result.files.single.path == null) return;

                          String filePath = result.files.single.path!;
                          File file = File(filePath);
                          int fileSize = await file.length();
                          String fileName = result.files.single.name;

                          Attachment newAttachment = Attachment(
                            inspectionItemId: item.id!,
                            fileName: fileName,
                            filePath: filePath,
                            fileSize: fileSize,
                            synced: 0
                          );

                          await DatabaseHelper.addAttachment(newAttachment);
                          await refreshAttachments();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Attached $fileName'))
                          );
                        },
                        child: const Text('Add Attachment')
                      )
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
                    InspectionItem updatedItem = InspectionItem(
                      id: item.id,
                      jobId: item.jobId,
                      componentName: item.componentName,
                      description: item.description,
                      result: selectedResult,
                      synced: 0
                    );

                    await DatabaseHelper.updateInspectionItem(updatedItem);
                    Navigator.pop(context);
                    loadItems();
                  },
                  child: const Text('Save')
                )
              ]
            );
          }
        );
      }
    );
  }

  Widget statusBox(String statusText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        color: Colors.white
      ),
      child: Text(statusText, style: const TextStyle(fontSize: 12))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.jobNumber)
      ),
      body: Column(
        children: [
          buildJobSummaryCard(),
          const Divider(height: 1),
          buildItemsHeader(),
          Expanded(child: buildItemsList())
        ]
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddItemDialog,
        label: const Text('New Item')
      )
    );
  }

  Widget buildJobSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.job.aircraft, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.job.description.isEmpty ? 'No description' : widget.job.description),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Status: '),
                statusBox(formatJobStatus(widget.job.status)),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    updateJobStatus(value);
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
            )
          ]
        )
      )
    );
  }

  Widget buildItemsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Inspection Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
        ]
      )
    );
  }

  Widget buildItemsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('No inspection items yet', style: TextStyle(color: Colors.black54))
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return buildItemCard(items[index]);
      }
    );
  }

  Widget buildItemCard(InspectionItem item) {
    String resultText = item.result;
    if (resultText == 'NOT_INSPECTED') resultText = 'NOT INSPECTED';
    if (resultText == 'N_A') resultText = 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(item.componentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
          ]
        ),
        trailing: statusBox(resultText),
        onTap: () {
          showEditItemDialog(item);
        }
      )
    );
  }
}
