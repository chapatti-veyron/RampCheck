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
    Map<String, dynamic> map = {};
    map['id'] = id;
    map['inspectionItemId'] = inspectionItemId;
    map['fileName'] = fileName;
    map['filePath'] = filePath;
    map['fileSize'] = fileSize;
    map['synced'] = synced;
    return map;
  }

  static Attachment fromMap(Map<String, dynamic> map) {
    Attachment attachment = Attachment(
      id: map['id'],
      inspectionItemId: map['inspectionItemId'],
      fileName: map['fileName'],
      filePath: map['filePath'],
      fileSize: map['fileSize'],
      synced: map['synced']
    );
    return attachment;
  }
}
