class InspectionItem {
  int? id;
  int jobId;
  String componentName;
  String description;
  String result;
  String notes;
  int synced;

  InspectionItem({
    this.id,
    required this.jobId,
    required this.componentName,
    required this.description,
    required this.result,
    required this.notes,
    required this.synced
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> m = {};
    m['id'] = id;
    m['jobId'] = jobId;
    m['componentName'] = componentName;
    m['description'] = description;
    m['result'] = result;
    m['notes'] = notes;
    m['synced'] = synced;
    return m;
  }

  static InspectionItem fromMap(Map<String, dynamic> m) {
    return InspectionItem(
      id: m['id'],
      jobId: m['jobId'],
      componentName: m['componentName'],
      description: m['description'],
      result: (m['result'] ?? 'NOT_INSPECTED') as String,
      notes: (m['notes'] ?? '') as String,
      synced: (m['synced'] ?? 0) as int
    );
  }
}
