// lib/DirectorsPages/director.dart
class Director {
  String? id;
  String userId;
  String position;
  String? nid;

  Director({
    this.id,
    required this.userId,
    required this.position,
    this.nid,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'position': position,
    };
    
    // ✅ Only add id if it exists and is not empty
    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    
    // ✅ Only add nid if it exists and is not empty
    if (nid != null && nid!.isNotEmpty) {
      data['nid'] = nid;
    }
    
    return data;
  }

  factory Director.fromJson(Map<String, dynamic> json) {
    // ✅ Check for different possible key names
    final String? idValue = json['id'] ?? json['_id'] ?? json['directorId'];
    final String? userIdValue = json['userId'] ?? json['userID'] ?? json['user_Id'];
    final String? positionValue = json['position'] ?? json['Position'];
    final String? nidValue = json['nid'] ?? json['NID'] ?? json['nidId'];
    
    print('📥 Director.fromJson - Raw data: $json');
    print('📥 Director.fromJson - Parsed: id=$idValue, userId=$userIdValue, position=$positionValue, nid=$nidValue');
    
    return Director(
      id: idValue,
      userId: userIdValue ?? '',
      position: positionValue ?? '',
      nid: nidValue,
    );
  }
}