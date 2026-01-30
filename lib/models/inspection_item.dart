class InspectionItem {
  int? id;
  int jobId;
  String componentName;
  String description;
  String result;
  int synced;

  InspectionItem({
    this.id,
    required this.jobId,
    required this.componentName,
    required this.description,
    required this.result,
    required this.synced
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['id'] = id;
    map['jobId'] = jobId;
    map['componentName'] = componentName;
    map['description'] = description;
    map['result'] = result;
    map['synced'] = synced;
    return map;
  }

  static InspectionItem fromMap(Map<String, dynamic> map) {
    InspectionItem item = InspectionItem(
      id: map['id'],
      jobId: map['jobId'],
      componentName: map['componentName'],
      description: map['description'],
      result: map['result'],
      synced: map['synced']
    );
    return item;
  }
}
