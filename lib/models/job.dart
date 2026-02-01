class Job {
  int? id;
  int? serverId;
  String jobNumber;
  String aircraft;
  String description;
  String status;
  int synced;

  Job({
    this.id,
    this.serverId,
    required this.jobNumber,
    required this.aircraft,
    required this.description,
    required this.status,
    required this.synced
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> m = {};
    m['id'] = id;
    m['serverId'] = serverId;
    m['jobNumber'] = jobNumber;
    m['aircraft'] = aircraft;
    m['description'] = description;
    m['status'] = status;
    m['synced'] = synced;
    return m;
  }

  static Job fromMap(Map<String, dynamic> m) {
    return Job(
      id: m['id'],
      serverId: m['serverId'],
      jobNumber: m['jobNumber'],
      aircraft: m['aircraft'],
      description: (m['description'] ?? '') as String,
      status: (m['status'] ?? 'pending') as String,
      synced: (m['synced'] ?? 0) as int
    );
  }
}
