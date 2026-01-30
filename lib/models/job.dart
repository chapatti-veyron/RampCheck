class Job {
  int? id;
  String jobNumber;
  String aircraft;
  String description;
  String status;
  int synced;

  Job({
    this.id,
    required this.jobNumber,
    required this.aircraft,
    required this.description,
    required this.status,
    required this.synced
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['id'] = id;
    map['jobNumber'] = jobNumber;
    map['aircraft'] = aircraft;
    map['description'] = description;
    map['status'] = status;
    map['synced'] = synced;
    return map;
  }

  static Job fromMap(Map<String, dynamic> map) {
    Job job = Job(
      id: map['id'],
      jobNumber: map['jobNumber'],
      aircraft: map['aircraft'],
      description: map['description'],
      status: map['status'],
      synced: map['synced']
    );
    return job;
  }
}
