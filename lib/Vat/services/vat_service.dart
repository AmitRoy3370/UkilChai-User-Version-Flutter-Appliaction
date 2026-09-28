// lib/vat/service/vat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as path;

import '../models/vat_model.dart';
import '../models/vat_response_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class VatService {
  // ============================================================
  // BASE URL HELPER
  // ============================================================
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // CREATE — Multipart/form-data
  // POST /api/vat/add
  // ============================================================
  /// [documents] should be a list of file paths (mobile) or
  /// [http.MultipartFile] (already wrapped) — we accept paths here
  /// and wrap them ourselves.
  static Future<Map<String, dynamic>> addVat({
    required String userId,
    required String adress,
    required String tinNo,
    required String buisnessName,
    required String tradeLicenseNo,
    required String annualTurnOver,
    required String mainProduct,
    required String natureOfBuisness,
    required int numberOfBuisness,
    required int numberOfEmployee,
    String? attachmentsId, // JSON array string e.g. '["id1","id2"]'
    List<String> documentPaths = const [], // local file paths
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/add');

    final request = http.MultipartRequest('POST', uri);

    // ---- Text fields ----
    request.fields['userId'] = userId;
    request.fields['adress'] = adress;
    request.fields['tinNo'] = tinNo;
    request.fields['buisnessName'] = buisnessName;
    request.fields['tradeLicenseNo'] = tradeLicenseNo;
    request.fields['annualTurnOver'] = annualTurnOver;
    request.fields['mainProduct'] = mainProduct;
    request.fields['natureOfBuisness'] = natureOfBuisness;
    request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    request.fields['numberOfEmployee'] = numberOfEmployee.toString();

    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    // ---- Files ----
    for (final filePath in documentPaths) {
      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'documents',
          filePath,
          contentType: _mediaTypeForFile(filePath),
        );
        request.files.add(multipartFile);
      } catch (_) {
        // skip invalid file
      }
    }

    // ---- Send ----
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // ============================================================
  // UPDATE — Multipart/form-data
  // PUT /api/vat/update/{id}
  // ============================================================
  static Future<Map<String, dynamic>> updateVat({
    required String id,
    required String userId,
    String? adress,
    String? tinNo,
    String? buisnessName,
    String? tradeLicenseNo,
    String? annualTurnOver,
    String? mainProduct,
    String? natureOfBuisness,
    int? numberOfBuisness,
    int? numberOfEmployee,
    String? attachmentsId,
    List<String> documentPaths = const [],
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/update/$id');

    final request = http.MultipartRequest('PUT', uri);

    request.fields['userId'] = userId;

    if (adress != null && adress.trim().isNotEmpty) {
      request.fields['adress'] = adress.trim();
    }
    if (tinNo != null && tinNo.trim().isNotEmpty) {
      request.fields['tinNo'] = tinNo.trim();
    }
    if (buisnessName != null && buisnessName.trim().isNotEmpty) {
      request.fields['buisnessName'] = buisnessName.trim();
    }
    if (tradeLicenseNo != null && tradeLicenseNo.trim().isNotEmpty) {
      request.fields['tradeLicenseNo'] = tradeLicenseNo.trim();
    }
    if (annualTurnOver != null && annualTurnOver.trim().isNotEmpty) {
      request.fields['annualTurnOver'] = annualTurnOver.trim();
    }
    if (mainProduct != null && mainProduct.trim().isNotEmpty) {
      request.fields['mainProduct'] = mainProduct.trim();
    }
    if (natureOfBuisness != null && natureOfBuisness.trim().isNotEmpty) {
      request.fields['natureOfBuisness'] = natureOfBuisness.trim();
    }
    if (numberOfBuisness != null) {
      request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    }
    if (numberOfEmployee != null) {
      request.fields['numberOfEmployee'] = numberOfEmployee.toString();
    }
    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    for (final filePath in documentPaths) {
      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'documents',
          filePath,
          contentType: _mediaTypeForFile(filePath),
        );
        request.files.add(multipartFile);
      } catch (_) {}
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // ============================================================
  // READ — By ID
  // GET /api/vat/{id}
  // ============================================================
  static Future<VatResponseModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat/$id');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    return VatResponseModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // GET /api/vat/all
  // ============================================================
  static Future<List<VatResponseModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat/all');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // READ — By User ID
  // GET /api/vat/search/userId?userId=...
  // ============================================================
  static Future<List<VatResponseModel>> findByUserId(String userId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/userId?userId=${Uri.encodeQueryComponent(userId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Adress
  // GET /api/vat/search/adress?adress=...
  // ============================================================
  static Future<List<VatResponseModel>> findByAdress(String adress) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/adress?adress=${Uri.encodeQueryComponent(adress)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By TIN No
  // GET /api/vat/search/tinNo?tinNo=...
  // ============================================================
  static Future<List<VatResponseModel>> findByTinNo(String tinNo) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/tinNo?tinNo=${Uri.encodeQueryComponent(tinNo)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Business Name
  // GET /api/vat/search/buisnessName?buisnessName=...
  // ============================================================
  static Future<List<VatResponseModel>> findByBuisnessName(
      String buisnessName) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/buisnessName?buisnessName=${Uri.encodeQueryComponent(buisnessName)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Trade License No
  // GET /api/vat/search/tradeLicenseNo?tradeLicenseNo=...
  // ============================================================
  static Future<List<VatResponseModel>> findByTradeLicenseNo(
      String tradeLicenseNo) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/tradeLicenseNo?tradeLicenseNo=${Uri.encodeQueryComponent(tradeLicenseNo)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Annual TurnOver
  // GET /api/vat/search/annualTurnOver?annualTurnOver=...
  // ============================================================
  static Future<List<VatResponseModel>> findByAnnualTurnOver(
      String annualTurnOver) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/annualTurnOver?annualTurnOver=${Uri.encodeQueryComponent(annualTurnOver)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Main Product
  // GET /api/vat/search/mainProduct?mainProduct=...
  // ============================================================
  static Future<List<VatResponseModel>> findByMainProduct(
      String mainProduct) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/mainProduct?mainProduct=${Uri.encodeQueryComponent(mainProduct)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Nature of Business
  // GET /api/vat/search/natureOfBuisness?natureOfBuisness=...
  // ============================================================
  static Future<List<VatResponseModel>> findByNatureOfBuisness(
      String natureOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/natureOfBuisness?natureOfBuisness=${Uri.encodeQueryComponent(natureOfBuisness)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Business >=
  // GET /api/vat/search/numberOfBuisness/greaterThanEqual?numberOfBuisness=N
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfBuisnessGTE(
      int numberOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfBuisness/greaterThanEqual?numberOfBuisness=$numberOfBuisness');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Business <=
  // GET /api/vat/search/numberOfBuisness/lessThanEqual?numberOfBuisness=N
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfBuisnessLTE(
      int numberOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfBuisness/lessThanEqual?numberOfBuisness=$numberOfBuisness');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Employee >=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfEmployeeGTE(
      int numberOfEmployee) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfEmployee/greaterThanEqual?numberOfEmployee=$numberOfEmployee');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Employee <=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfEmployeeLTE(
      int numberOfEmployee) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfEmployee/lessThanEqual?numberOfEmployee=$numberOfEmployee');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Document
  // GET /api/vat/search/documents?documents=...
  // ============================================================
  static Future<List<VatResponseModel>> findByDocuments(
      String documents) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/documents?documents=${Uri.encodeQueryComponent(documents)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // DELETE /api/vat/delete/{id}?userId=...
  // ============================================================
  static Future<bool> deleteVat({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
    final response = await http.delete(uri);

    final json = _handleResponse(response);
    return json['status'] == 'success';
  }

  // ============================================================
  // HELPERS
  // ============================================================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          'Invalid server response (${response.statusCode}): ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          json['message'] ?? 'Request failed (${response.statusCode})');
    }

    if (json['status'] == 'error') {
      throw Exception(json['message'] ?? 'Unknown error');
    }

    return json;
  }

  static MediaType _mediaTypeForFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}