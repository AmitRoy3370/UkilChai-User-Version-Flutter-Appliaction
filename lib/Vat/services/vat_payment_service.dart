// lib/vat/service/vat_payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/vat_payment_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class VatPaymentService {
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // CREATE
  // POST /api/vat-payment/add?userId=...
  // ============================================================
  static Future<VatPaymentModel> addPayment({
    required VatPaymentModel payment,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/add?userId=${Uri.encodeQueryComponent(userId)}');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payment.toJson()),
    );

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // UPDATE
  // PUT /api/vat-payment/update/{id}?userId=...
  // ============================================================
  static Future<VatPaymentModel> updatePayment({
    required String id,
    required VatPaymentModel payment,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/update/$id?userId=${Uri.encodeQueryComponent(userId)}');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payment.toJson()),
    );

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — By ID
  // GET /api/vat-payment/{id}
  // ============================================================
  static Future<VatPaymentModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat-payment/$id');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // GET /api/vat-payment/all
  // ============================================================
  static Future<List<VatPaymentModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat-payment/all');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Sender User ID
  // GET /api/vat-payment/search/senderUserId?senderUserId=...
  // ============================================================
  static Future<List<VatPaymentModel>> findBySenderUserId(
      String senderUserId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/senderUserId?senderUserId=${Uri.encodeQueryComponent(senderUserId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Sender Phone Number (containing, ignore case)
  // GET /api/vat-payment/search/senderPhoneNumber?senderPhoneNumber=...
  // ============================================================
  static Future<List<VatPaymentModel>> findBySenderPhoneNumber(
      String senderPhoneNumber) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/senderPhoneNumber?senderPhoneNumber=${Uri.encodeQueryComponent(senderPhoneNumber)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Receiver Phone Number
  // GET /api/vat-payment/search/receiverPhoneNumber?receiverPhoneNumber=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByReceiverPhoneNumber(
      String receiverPhoneNumber) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/receiverPhoneNumber?receiverPhoneNumber=${Uri.encodeQueryComponent(receiverPhoneNumber)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID
  // GET /api/vat-payment/search/vatId?vatId=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByVatId(String vatId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/vatId?vatId=${Uri.encodeQueryComponent(vatId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID and Sender User ID
  // GET /api/vat-payment/search/vatIdAndSenderUserId?vatId=...&senderUserId=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByVatIdAndSenderUserId({
    required String vatId,
    required String senderUserId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/vatIdAndSenderUserId?vatId=${Uri.encodeQueryComponent(vatId)}&senderUserId=${Uri.encodeQueryComponent(senderUserId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Amount >=
  // GET /api/vat-payment/search/amount/greaterThanEqual?amount=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByAmountGTE(double amount) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/amount/greaterThanEqual?amount=$amount');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Amount <=
  // GET /api/vat-payment/search/amount/lessThanEqual?amount=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByAmountLTE(double amount) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/amount/lessThanEqual?amount=$amount');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Transaction ID (containing, ignore case)
  // GET /api/vat-payment/search/transactionId/containing?transactionId=...
  // ============================================================
  static Future<List<VatPaymentModel>> findByTransactionIdContaining(
      String transactionId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/transactionId/containing?transactionId=${Uri.encodeQueryComponent(transactionId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Transaction ID (exact)
  // GET /api/vat-payment/search/transactionId?transactionId=...
  // ============================================================
  static Future<VatPaymentModel> findByTransactionId(
      String transactionId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/transactionId?transactionId=${Uri.encodeQueryComponent(transactionId)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // SEARCH — Sending Time After (ISO-8601)
  // GET /api/vat-payment/search/sendingTime/after?sendingTime=...
  // ============================================================
  static Future<List<VatPaymentModel>> findBySendingTimeAfter(
      DateTime sendingTime) async {
    final iso = sendingTime.toUtc().toIso8601String();
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/sendingTime/after?sendingTime=${Uri.encodeQueryComponent(iso)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Sending Time Before (ISO-8601)
  // GET /api/vat-payment/search/sendingTime/before?sendingTime=...
  // ============================================================
  static Future<List<VatPaymentModel>> findBySendingTimeBefore(
      DateTime sendingTime) async {
    final iso = sendingTime.toUtc().toIso8601String();
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/sendingTime/before?sendingTime=${Uri.encodeQueryComponent(iso)}');
    final response = await http.get(uri);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // DELETE /api/vat-payment/delete/{id}?userId=...
  // ============================================================
  static Future<bool> deletePayment({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
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