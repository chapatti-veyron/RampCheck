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

    int? id = widget.job.id;
    if (id == null) {
      setState(() {
        items = [];
        loading = false;
      });
      return;
    }

    List<InspectionItem> list = await DatabaseHelper.getInspectionItemsForJob(id);

    setState(() {
      items = list;
      loading = false;
    });
  }

  String s(String v) {
    if (v == 'NOT_INSPECTED') return 'NOT INSPECTED';
    if (v == 'N_A') return 'N/A';
    return v;
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

  void addItemDialog() {
    TextEditingController a = TextEditingController();
    TextEditingController b = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: a,
                decoration: const InputDecoration(
                  labelText: 'Component',
                  border: OutlineInputBorder()
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: b,
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

                String name = a.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Component is required'))
                  );
                  return;
                }

                InspectionItem x = InspectionItem(
                  jobId: widget.job.id!,
                  componentName: name,
                  description: b.text.trim(),
                  result: 'NOT_INSPECTED',
                  notes: '',
                  synced: 0
                );

                await DatabaseHelper.addInspectionItem(x);
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
    String res = item.result;
    List<Attachment> atts = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setD) {
            Future<void> refresh() async {
              List<Attachment> newList = await DatabaseHelper.getAttachmentsForInspectionItem(item.id!);
              setD(() {
                atts = newList;
              });
            }

            return AlertDialog(
              title: Text(item.componentName),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: res,
                      decoration: const InputDecoration(
                        labelText: 'Result',
                        border: OutlineInputBorder()
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NOT_INSPECTED', child: Text('Not inspected')),
                        DropdownMenuItem(value: 'PASS', child: Text('Pass')),
                        DropdownMenuItem(value: 'FAIL', child: Text('Fail')),
                        DropdownMenuItem(value: 'N_A', child: Text('N/A'))
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setD(() {
                          res = v;
                        });
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Attachments (${atts.length})', style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(height: 8),
                    if (atts.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No attachments', style: TextStyle(color: Colors.black54))
                      )
                    else
                      Column(
                        children: atts.map((a) {
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
                                      Text(a.fileName, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text('${(a.fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11, color: Colors.black54))
                                    ]
                                  )
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (a.id == null) return;
                                    await DatabaseHelper.deleteAttachment(a.id!);
                                    await refresh();
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
                          FilePickerResult? r = await FilePicker.platform.pickFiles(allowMultiple: false);
                          if (r == null) return;
                          if (r.files.isEmpty) return;
                          if (r.files.single.path == null) return;

                          String path = r.files.single.path!;
                          File f = File(path);
                          int size = await f.length();
                          String name = r.files.single.name;

                          Attachment n = Attachment(
                            inspectionItemId: item.id!,
                            fileName: name,
                            filePath: path,
                            fileSize: size,
                            synced: 0
                          );

                          await DatabaseHelper.addAttachment(n);
                          await refresh();
                        },
                        child: const Text('Add Attachment')
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
                    InspectionItem up = InspectionItem(
                      id: item.id,
                      jobId: item.jobId,
                      componentName: item.componentName,
                      description: item.description,
                      result: res,
                      notes: notes.text,
                      synced: 0
                    );

                    await DatabaseHelper.updateInspectionItem(up);
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
        title: Text(widget.job.jobNumber)
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
                Row(
                  children: [
                    const Text('Status: '),
                    box(s(widget.job.status))
                  ]
                )
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
                Text('${items.length}', style: const TextStyle(color: Colors.black54))
              ]
            )
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('No items', style: TextStyle(color: Colors.black54)))
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
                              title: Text(it.componentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.description),
                                  if (it.notes.isNotEmpty) Text('Notes: ${it.notes}')
                                ]
                              ),
                              trailing: box(s(it.result)),
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
