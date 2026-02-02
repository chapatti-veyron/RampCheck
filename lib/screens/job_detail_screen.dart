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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
    });

    if (widget.job.id == null) {
      setState(() {
        items = [];
        loading = false;
      });
      return;
    }

    List<InspectionItem> list = await DatabaseHelper.getInspectionItemsForJob(widget.job.id!);

    setState(() {
      items = list;
      loading = false;
    });
  }

  void addItemDialog() {
    TextEditingController comp = TextEditingController();
    TextEditingController desc = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Inspection Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: comp,
                decoration: const InputDecoration(
                  labelText: 'Component',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.job.id == null) return;

                String name = comp.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Component required'))
                  );
                  return;
                }

                InspectionItem item = InspectionItem(
                  jobId: widget.job.id!,
                  componentName: name,
                  description: desc.text.trim(),
                  result: 'NOT_INSPECTED',
                  notes: '',
                  synced: 0
                );

                await DatabaseHelper.addInspectionItem(item);
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

  Future<void> editDialog(InspectionItem item) async {
    if (item.id == null) return;

    TextEditingController notes = TextEditingController(text: item.notes);
    String result = item.result;
    List<Attachment> attachments = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> refreshAttachments() async {
              List<Attachment> newList = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);
              setDialogState(() {
                attachments = newList;
              });
            }

            return AlertDialog(
              title: Text(item.componentName),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(item.description),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: result,
                      decoration: const InputDecoration(
                        labelText: 'Result',
                        border: OutlineInputBorder()
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NOT_INSPECTED', child: Text('Not Inspected')),
                        DropdownMenuItem(value: 'PASS', child: Text('Pass')),
                        DropdownMenuItem(value: 'FAIL', child: Text('Fail')),
                        DropdownMenuItem(value: 'N_A', child: Text('N/A'))
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            result = v;
                          });
                        }
                      }
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder()
                      )
                    ),
                    const SizedBox(height: 12),
                    Text('Attachments: ${attachments.length}'),
                    const SizedBox(height: 8),
                    if (attachments.isEmpty)
                      const Text('No attachments')
                    else
                      Column(
                        children: attachments.map((a) {
                          return ListTile(
                            title: Text(a.fileName),
                            subtitle: Text('${(a.fileSize / 1024).toStringAsFixed(1)} KB'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                if (a.id != null) {
                                  await DatabaseHelper.deleteAttachment(a.id!);
                                  await refreshAttachments();
                                }
                              }
                            )
                          );
                        }).toList()
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? r = await FilePicker.platform.pickFiles();
                        if (r == null) return;
                        if (r.files.isEmpty) return;
                        if (r.files.single.path == null) return;

                        String path = r.files.single.path!;
                        File f = File(path);
                        int size = await f.length();

                        Attachment newAtt = Attachment(
                          inspectionItemId: item.id!,
                          fileName: r.files.single.name,
                          filePath: path,
                          fileSize: size,
                          synced: 0
                        );

                        await DatabaseHelper.addAttachment(newAtt);
                        await refreshAttachments();
                      },
                      child: const Text('Add Attachment')
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
                    InspectionItem updated = InspectionItem(
                      id: item.id,
                      jobId: item.jobId,
                      componentName: item.componentName,
                      description: item.description,
                      result: result,
                      notes: notes.text,
                      synced: 0
                    );

                    await DatabaseHelper.updateInspectionItem(updated);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.jobNumber),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              color: Colors.white
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.job.aircraft, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(widget.job.description.isEmpty ? 'No description' : widget.job.description),
                const SizedBox(height: 12),
                Text('Status: ${widget.job.status.toUpperCase()}')
              ]
            )
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Inspection Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${items.length}')
              ]
            )
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('No items'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          InspectionItem it = items[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              color: Colors.white
                            ),
                            child: ListTile(
                              title: Text(it.componentName),
                              subtitle: Text(it.description),
                              trailing: Text(it.result),
                              onTap: () => editDialog(it)
                            )
                          );
                        }
                      )
          )
        ]
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addItemDialog,
        label: const Text('New Item')
      )
    );
  }
}