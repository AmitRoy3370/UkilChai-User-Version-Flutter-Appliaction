import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../RegistrationPage/UserGender.dart';
import '../RegistrationPage/Gender.dart';

class UserGenderService {
  final Dio _dio;
  final String baseUrl;

  UserGenderService({
    Dio? dio,
    this.baseUrl = 'https://ukilchai.abrdns.com',
  }) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authorization header if token is available
          final token = getAuthToken(); // Implement this based on your auth system
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          if (kDebugMode) {
            print('Request: ${options.method} ${options.path}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('Response: ${response.statusCode}');
            print('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioError error, handler) {
          if (kDebugMode) {
            print('Error: ${error.message}');
            print('Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Mock function - replace with your actual auth token implementation
  String? getAuthToken() {
    // Implement your token retrieval logic here
    // Example: return await SecureStorage.getToken();
    return null;
  }

  // ============ CREATE ============
  /// POST /api/user-gender/create?userId={userId}
  Future<UserGender> createUserGender({
    required String userId,
    required Gender gender,
  }) async {
    try {
      final userGender = UserGender(
        userId: userId,
        gender: gender,
      );

      final response = await _dio.post(
        '/api/user-gender/create',
        queryParameters: {'userId': userId},
        data: userGender.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserGender.fromJson(response.data);
      } else {
        throw Exception('Failed to create user gender: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error creating user gender: $e');
    }
  }

  // ============ UPDATE ============
  /// PUT /api/user-gender/update/{id}?userId={userId}
  Future<UserGender> updateUserGender({
    required String id,
    required String userId,
    required UserGender userGender,
  }) async {
    try {
      final response = await _dio.put(
        '/api/user-gender/update/$id',
        queryParameters: {'userId': userId},
        data: userGender.toJson(),
      );

      if (response.statusCode == 200) {
        return UserGender.fromJson(response.data);
      } else {
        throw Exception('Failed to update user gender: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error updating user gender: $e');
    }
  }

  // ============ FIND BY ID ============
  /// GET /api/user-gender/find/{id}
  Future<UserGender> findById(String id) async {
    try {
      final response = await _dio.get(
        '/api/user-gender/find/$id',
      );

      if (response.statusCode == 200) {
        return UserGender.fromJson(response.data);
      } else {
        throw Exception('Failed to find user gender: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user gender: $e');
    }
  }

  // ============ FIND ALL ============
  /// GET /api/user-gender/find-all
  Future<List<UserGender>> findAll() async {
    try {
      final response = await _dio.get(
        '/api/user-gender/find-all',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserGender.fromJson(json)).toList();
      } else {
        throw Exception('Failed to find all user genders: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding all user genders: $e');
    }
  }

  // ============ FIND BY USER ID ============
  /// GET /api/user-gender/find-by-user/{userId}
  Future<UserGender> findByUserId(String userId) async {
    try {
      final response = await _dio.get(
        '/api/user-gender/find-by-user/$userId',
      );

      if (response.statusCode == 200) {
        return UserGender.fromJson(response.data);
      } else {
        throw Exception('Failed to find user gender by user ID: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user gender by user ID: $e');
    }
  }

  // ============ FIND BY GENDER ============
  /// GET /api/user-gender/find-by-gender?gender={gender}
  Future<List<UserGender>> findByGender(Gender gender) async {
    try {
      final response = await _dio.get(
        '/api/user-gender/find-by-gender',
        queryParameters: {'gender': gender.name},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserGender.fromJson(json)).toList();
      } else {
        throw Exception('Failed to find user genders by gender: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user genders by gender: $e');
    }
  }

  // ============ FIND BY USER IDS ============
  /// POST /api/user-gender/find-by-user-ids
  Future<List<UserGender>> findByUserIds(List<String> userIds) async {
    try {
      final response = await _dio.post(
        '/api/user-gender/find-by-user-ids',
        data: userIds, // Send as array directly
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserGender.fromJson(json)).toList();
      } else {
        throw Exception('Failed to find user genders by user IDs: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user genders by user IDs: $e');
    }
  }

  // Alternative: If the API expects { "usersId": [...] } format
  Future<List<UserGender>> findByUserIdsWithMap(List<String> userIds) async {
    try {
      final response = await _dio.post(
        '/api/user-gender/find-by-user-ids',
        data: {'usersId': userIds},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserGender.fromJson(json)).toList();
      } else {
        throw Exception('Failed to find user genders by user IDs: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user genders by user IDs: $e');
    }
  }

  // ============ DELETE ============
  /// DELETE /api/user-gender/delete/{id}?userId={userId}
  Future<bool> deleteUserGender({
    required String id,
    required String userId,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/user-gender/delete/$id',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user gender: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error deleting user gender: $e');
    }
  }

  // ============ CHECK USER GENDER EXISTS ============
  /// GET /api/user-gender/check/{userId}
  Future<bool> checkUserGenderExists(String userId) async {
    try {
      final response = await _dio.get(
        '/api/user-gender/check/$userId',
      );

      if (response.statusCode == 200) {
        return response.data == true;
      } else {
        return false;
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error checking user gender existence: $e');
    }
  }

  // ============ FIND BY USER ID (Alternative) ============
  /// GET /api/user-gender/find-by-user-param?userId={userId}
  Future<UserGender> findByUserIdParam(String userId) async {
    try {
      final response = await _dio.get(
        '/api/user-gender/find-by-user-param',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        return UserGender.fromJson(response.data);
      } else {
        throw Exception('Failed to find user gender by user ID param: ${response.data}');
      }
    } on DioError catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user gender by user ID param: $e');
    }
  }

  // ============ ERROR HANDLING ============
  Exception _handleDioError(DioError e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      switch (statusCode) {
        case 400:
          return Exception('Bad Request: ${_extractErrorMessage(data)}');
        case 401:
          return Exception('Unauthorized: Please check your authentication');
        case 403:
          return Exception('Forbidden: You do not have permission');
        case 404:
          return Exception('Not Found: ${_extractErrorMessage(data)}');
        case 409:
          return Exception('Conflict: ${_extractErrorMessage(data)}');
        case 500:
          return Exception('Internal Server Error: Please try again later');
        default:
          return Exception('Error ${statusCode}: ${_extractErrorMessage(data)}');
      }
    } else if (e.type == DioErrorType.connectTimeout) {
      return Exception('Connection timeout: Please check your internet connection');
    } else if (e.type == DioErrorType.sendTimeout) {
      return Exception('Send timeout: Please try again');
    } else if (e.type == DioErrorType.receiveTimeout) {
      return Exception('Receive timeout: Please try again');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Unknown error';
    if (data is String) return data;
    if (data is Map) {
      // Try to extract error message from different formats
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('Error')) return data['Error'].toString();
      return data.toString();
    }
    return data.toString();
  }
}