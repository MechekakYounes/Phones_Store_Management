import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ui/core/config/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Main HTTP client
  final http.Client _client = http.Client();

  /// Handle API responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = json.decode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      throw ApiException(
        message: responseBody['message'] ?? 'Something went wrong',
        statusCode: statusCode,
        errors: responseBody['errors'],
      );
    }
  }

  /// Login API
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/login');
      
      final response = await _client.post(
        url,
        headers: ApiConfig.headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Logout API
  Future<void> logout(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/logout');
      
      final response = await _client.post(
        url,
        headers: ApiConfig.authHeaders(token),
      ).timeout(ApiConfig.timeout);

      _handleResponse(response);
    } catch (e) {
      // Even if logout fails, we still want to clear local data
      rethrow;
    }
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/user');
      
      final response = await _client.get(
        url,
        headers: ApiConfig.authHeaders(token),
      ).timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Check if super admin exists (for setup)
  Future<Map<String, dynamic>> checkSuperAdmin() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/check-super-admin');
      
      final response = await _client.get(url).timeout(ApiConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Setup super admin (first time only)
  Future<Map<String, dynamic>> setupSuperAdmin({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/setup-super-admin');
      
      final response = await _client.post(
        url,
        headers: ApiConfig.headers,
        body: json.encode({
          'name': name,
          'username': username,
          'password': password,
          'password_confirmation': password,
          'phone': phone,
        }),
      ).timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
  
  /// Get user-friendly error message
  String getUserMessage() {
    if (errors != null && errors is Map<String, dynamic>) {
      final errorMap = errors as Map<String, dynamic>;
      final firstError = errorMap.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first;
      }
    }
    return message;
  }
}