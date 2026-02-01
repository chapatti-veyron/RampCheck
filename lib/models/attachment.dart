class Attachment {
  int? id;
  int inspectionItemId;
  String fileName;
  String filePath;
  int fileSize;
  int synced;

  Attachment({
    this.id,
    required this.inspectionItemId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.synced
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> m = {};
    m['id'] = id;
    m['inspectionItemId'] = inspectionItemId;
    m['fileName'] = fileName;
    m['filePath'] = filePath;
    m['fileSize'] = fileSize;
    m['synced'] = synced;
    return m;
  }

  static Attachment fromMap(Map<String, dynamic> m) {
    return Attachment(
      id: m['id'],
      inspectionItemId: m['inspectionItemId'],
      fileName: m['fileName'],
      filePath: m['filePath'],
      fileSize: m['fileSize'],
      synced: (m['synced'] ?? 0) as int
    );
  }
}
