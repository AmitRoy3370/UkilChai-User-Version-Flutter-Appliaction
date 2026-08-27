// lib/DirectorsPages/director_response.dart
import '../CompanyPages/company_information.dart';

class DirectorResponse {
  String? id;
  String userId;
  String userName;
  String? userContactInfoId;
  String? email;
  String? phone;
  String? locationId;
  String? locationName;
  double? latitude;
  double? longitude;
  String position;
  String? nid;
  String? profileImageId;
  List<CompanyInformation> companies;

  DirectorResponse({
    this.id,
    required this.userId,
    required this.userName,
    this.userContactInfoId,
    this.email,
    this.phone,
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.position,
    this.nid,
    this.companies = const [],
    this.profileImageId,
  });

  factory DirectorResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Check for different possible key names
    final String? idValue = json['id'] ?? json['_id'] ?? json['directorId'];
    final String? userIdValue = json['userId'] ?? json['userID'] ?? json['user_Id'];
    final String? userNameValue = json['userName'] ?? json['fullName'] ?? json['name'];
    final String? positionValue = json['position'] ?? json['Position'];
    final String? nidValue = json['nid'] ?? json['NID'] ?? json['nidId'];
    
    return DirectorResponse(
      id: idValue,
      userId: userIdValue ?? '',
      userName: userNameValue ?? '',
      userContactInfoId: json['userContactInfnfoId'] ?? json['userContactInfoId'],
      email: json['email'],
      phone: json['phone'],
      locationId: json['locationId'],
      locationName: json['locationName'],
      latitude: json['lattitude']?.toDouble() ?? json['latitude']?.toDouble(),
      longitude: json['longititude']?.toDouble() ?? json['longitude']?.toDouble(),
      position: positionValue ?? '',
      nid: nidValue,
      companies: json['companies'] != null
          ? (json['companies'] as List)
              .map((e) => CompanyInformation.fromJson(e))
              .toList()
          : [],
      profileImageId: json['profileImageId'] ?? json['profileImage'],
    );
  }
}