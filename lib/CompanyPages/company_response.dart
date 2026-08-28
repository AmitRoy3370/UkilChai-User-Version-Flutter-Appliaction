// lib/CompanyPages/company_response.dart
import 'capital.dart';
import 'subscription.dart';

class CompanyResponse {
  String? id;
  String companyName;
  String type;
  String natureOfBusiness;
  String category;
  String? officeRegistryId;
  List<String>? shareHolders;
  List<String>? documents;
  List<String>? directorsId;
  List<String>? shareHoldersName;
  List<String>? directorsName;
  String? authorized;
  List<String>? capital;
  String? creatorId;
  String? creatorName;
  List<Capital>? capitals;
  List<Subscription>? subscriptions;

  CompanyResponse({
    this.id,
    required this.companyName,
    required this.type,
    required this.natureOfBusiness,
    required this.category,
    this.officeRegistryId,
    this.shareHolders,
    this.documents,
    this.directorsId,
    this.shareHoldersName,
    this.directorsName,
    this.authorized,
    this.capital,
    this.creatorId,
    this.creatorName,
    this.capitals,
    this.subscriptions,
  });

  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    return CompanyResponse(
      id: json['id'],
      companyName: json['companyName'] ?? '',
      type: json['type'] ?? '',
      natureOfBusiness: json['natureOfBuisness'] ?? '',
      category: json['category'] ?? '',
      // ✅ officeRegistryId with null safety - only set if not null and not empty
      officeRegistryId: json['officeRegistryId'] != null && json['officeRegistryId'].toString().isNotEmpty
          ? json['officeRegistryId'].toString()
          : null,
      shareHolders: json['shareHolders'] != null
          ? List<String>.from(json['shareHolders'])
          : [],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
      directorsId: json['directorsId'] != null
          ? List<String>.from(json['directorsId'])
          : [],
      shareHoldersName: json['shareHoldersName'] != null
          ? List<String>.from(json['shareHoldersName'])
          : [],
      directorsName: json['directorsName'] != null
          ? List<String>.from(json['directorsName'])
          : [],
      authorized: json['authorized'],
      capital: json['capital'] != null
          ? List<String>.from(json['capital'])
          : [],
      creatorId: json['creatorId'],
      creatorName: json['creatorName'],
      capitals: json['capitals'] != null
          ? (json['capitals'] as List)
              .map((e) => Capital.fromJson(e))
              .toList()
          : [],
      subscriptions: json['subscriptions'] != null
          ? (json['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e))
              .toList()
          : [],
    );
  }

  // ✅ Optional: Add a toJson method if needed for sending back to server
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'type': type,
      'natureOfBuisness': natureOfBusiness,
      'category': category,
      if (officeRegistryId != null && officeRegistryId!.isNotEmpty)
        'officeRegistryId': officeRegistryId,
      if (shareHolders != null && shareHolders!.isNotEmpty)
        'shareHolders': shareHolders,
      if (documents != null && documents!.isNotEmpty)
        'documents': documents,
      if (directorsId != null && directorsId!.isNotEmpty)
        'directorsId': directorsId,
      if (shareHoldersName != null && shareHoldersName!.isNotEmpty)
        'shareHoldersName': shareHoldersName,
      if (directorsName != null && directorsName!.isNotEmpty)
        'directorsName': directorsName,
      if (authorized != null) 'authorized': authorized,
      if (capital != null && capital!.isNotEmpty)
        'capital': capital,
      if (creatorId != null) 'creatorId': creatorId,
      if (creatorName != null) 'creatorName': creatorName,
      if (capitals != null && capitals!.isNotEmpty)
        'capitals': capitals?.map((e) => e.toJson()).toList(),
      if (subscriptions != null && subscriptions!.isNotEmpty)
        'subscriptions': subscriptions?.map((e) => e.toJson()).toList(),
    };
  }

  // ✅ Helper method to get formatted officeRegistryId
  String? get formattedOfficeRegistryId {
    if (officeRegistryId == null || officeRegistryId!.isEmpty) {
      return null;
    }
    // If the ID is long, show first 8 and last 4 characters
    if (officeRegistryId!.length > 12) {
      return '${officeRegistryId!.substring(0, 8)}...${officeRegistryId!.substring(officeRegistryId!.length - 4)}';
    }
    return officeRegistryId;
  }

  @override
  String toString() {
    return 'CompanyResponse{id: $id, companyName: $companyName, type: $type, '
        'natureOfBusiness: $natureOfBusiness, category: $category, '
        'officeRegistryId: $officeRegistryId, shareHolders: $shareHolders, '
        'documents: $documents, directorsId: $directorsId, '
        'shareHoldersName: $shareHoldersName, directorsName: $directorsName, '
        'authorized: $authorized, capital: $capital, creatorId: $creatorId, '
        'creatorName: $creatorName, capitals: $capitals, subscriptions: $subscriptions}';
  }
}