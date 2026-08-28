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
      shareHoldersName: json['shareHoldersName'] != null
          ? List<String>.from(json['shareHoldersName'])
          : null,
      directorsName: json['directorsName'] != null
          ? List<String>.from(json['directorsName'])
          : null,
      authorized: json['authorized'],
      capital: json['capital'] != null
          ? List<String>.from(json['capital'])
          : null,
      creatorId: json['creatorId'],
      creatorName: json['creatorName'],
      capitals: json['capitals'] != null
          ? (json['capitals'] as List)
              .map((e) => Capital.fromJson(e))
              .toList()
          : null,
      subscriptions: json['subscriptions'] != null
          ? (json['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e))
              .toList()
          : null,
    );
  }
}