class CaseModel {
  final String id;
  final String caseName;
  final String userId, userName;
  final String? userFullName;
  final String advocateId, advocateName;
  final String? advocateFullName;
  final String caseType;
  final List<String> attachmentsId;
  final String issuedTime;

  CaseModel({
    required this.id,
    required this.caseName,
    required this.userId,
    required this.userName,
    required this.userFullName,
    required this.advocateId,
    required this.advocateName,
    required this.advocateFullName,
    required this.caseType,
    required this.attachmentsId,
    required this.issuedTime,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json["id"],
      caseName: json["caseName"],
      userId: json["userId"],
      userName: json['userName'],
      userFullName: json['userFullName'],
      advocateId: json["advocateId"],
      advocateName: json['advocateName'],
      advocateFullName: json['advocateFullName'],
      caseType: json["caseType"],
      attachmentsId:
      json["attachmentsId"] == null
          ? []
          : List<String>.from(json["attachmentsId"]),
      issuedTime: json["issuedTime"],
    );
  }
}
