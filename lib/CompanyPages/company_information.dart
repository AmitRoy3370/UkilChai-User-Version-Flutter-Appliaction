// lib/CompanyPages/company_information.dart
class CompanyInformation {
  String? id;
  String companyName;
  String type;
  String natureOfBusiness;
  String category;
  String? officeRegistryId;
  List<String>? shareHolders;
  List<String>? documents;
  List<String>? directorsId;
  String? authorized;
  List<String>? capital;
  String? creatorId;

  CompanyInformation({
    this.id,
    required this.companyName,
    required this.type,
    required this.natureOfBusiness,
    required this.category,
    this.officeRegistryId,
    this.shareHolders,
    this.documents,
    this.directorsId,
    this.authorized,
    this.capital,
    this.creatorId,
  });

  // Factory constructor for creating from JSON
  factory CompanyInformation.fromJson(Map<String, dynamic> json) {
    return CompanyInformation(
      id: json['id'],
      companyName: json['companyName'] ?? '',
      type: json['type'] ?? '',
      natureOfBusiness: json['natureOfBuisness'] ?? '',
      category: json['category'] ?? '',
      officeRegistryId: json['officeRegistryId'],
      shareHolders: json['shareHolders'] != null
          ? List<String>.from(json['shareHolders'])
          : null,
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
      directorsId: json['directorsId'] != null
          ? List<String>.from(json['directorsId'])
          : null,
      authorized: json['authorized'],
      capital: json['capital'] != null
          ? List<String>.from(json['capital'])
          : null,
      creatorId: json['creatorId'],
    );
  }

  // Convert to JSON for sending to server
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'type': type,
      'natureOfBuisness': natureOfBusiness,
      'category': category,
      if (officeRegistryId != null) 'officeRegistryId': officeRegistryId,
      if (shareHolders != null && shareHolders!.isNotEmpty) 
        'shareHolders': shareHolders,
      if (documents != null && documents!.isNotEmpty) 
        'documents': documents,
      if (directorsId != null && directorsId!.isNotEmpty) 
        'directorsId': directorsId,
      if (authorized != null) 'authorized': authorized,
      if (capital != null && capital!.isNotEmpty) 
        'capital': capital,
      if (creatorId != null) 'creatorId': creatorId,
    };
  }

  // Copy with method for updating
  CompanyInformation copyWith({
    String? id,
    String? companyName,
    String? type,
    String? natureOfBusiness,
    String? category,
    String? officeRegistryId,
    List<String>? shareHolders,
    List<String>? documents,
    List<String>? directorsId,
    String? authorized,
    List<String>? capital,
    String? creatorId,
  }) {
    return CompanyInformation(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      type: type ?? this.type,
      natureOfBusiness: natureOfBusiness ?? this.natureOfBusiness,
      category: category ?? this.category,
      officeRegistryId: officeRegistryId ?? this.officeRegistryId,
      shareHolders: shareHolders ?? this.shareHolders,
      documents: documents ?? this.documents,
      directorsId: directorsId ?? this.directorsId,
      authorized: authorized ?? this.authorized,
      capital: capital ?? this.capital,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  @override
  String toString() {
    return 'CompanyInformation{id: $id, companyName: $companyName, type: $type, '
        'natureOfBusiness: $natureOfBusiness, category: $category, '
        'officeRegistryId: $officeRegistryId, shareHolders: $shareHolders, '
        'documents: $documents, directorsId: $directorsId, authorized: $authorized, '
        'capital: $capital, creatorId: $creatorId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyInformation &&
        other.id == id &&
        other.companyName == companyName;
  }

  @override
  int get hashCode => id.hashCode ^ companyName.hashCode;
}