// lib/vat/service/vat_registration_process_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/vat_registration_process_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class VatRegistrationProcessService {
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // CREATE
  // POST /api/vat-registration/add?userId=...
  // ============================================================
  static Future<VatRegistrationProcessModel> addProcess({
    required VatRegistrationProcessModel process,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/add?userId=${Uri.encodeQueryComponent(userId)}');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(process.toJson()),
    );

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // UPDATE
  // PUT /api/vat-registration/update/{id}?userId=...
  // ============================================================
  static Future<VatRegistrationProcessModel> updateProcess({
    required String id,
    required VatRegistrationProcessModel process,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/update/$id?userId=${Uri.encodeQueryComponent(userId)}');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(process.toJson()),
    );

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — By ID
  // GET /api/vat-registration/{id}
  // ============================================================
  static Future<VatRegistrationProcessModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat-registration/$id');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // GET /api/vat-registration/all
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat-registration/all');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID (single)
  // GET /api/vat-registration/search/vatId?vatId=...
  // ============================================================
  static Future<VatRegistrationProcessModel> findByVatId(String vatId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/vatId?vatId=${Uri.encodeQueryComponent(vatId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // SEARCH — By VAT ID IN (list)
  // GET /api/vat-registration/search/vatIdIn?vatsId=id1&vatsId=id2
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByVatIdIn(
      List<String> vatsId) async {
    final query = vatsId
        .map((id) => 'vatsId=${Uri.encodeQueryComponent(id)}')
        .join('&');
    final uri = Uri.parse('${_baseUrl}vat-registration/search/vatIdIn?$query');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By User ID
  // GET /api/vat-registration/search/userId?userId=...
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByUserId(
      String userId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/userId?userId=${Uri.encodeQueryComponent(userId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Advocate ID
  // GET /api/vat-registration/search/advocateId?advocateId=...
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByAdvocateId(
      String advocateId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/advocateId?advocateId=${Uri.encodeQueryComponent(advocateId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Status
  // GET /api/vat-registration/search/status?status=true
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByStatus(
      bool status) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/status?status=$status');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Steps (containing, ignore case)
  // GET /api/vat-registration/search/steps?steps=...
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findBySteps(
      String steps) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/steps?steps=${Uri.encodeQueryComponent(steps)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // DELETE /api/vat-registration/delete/{id}?userId=...
  // ============================================================
  static Future<bool> deleteProcess({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
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
}