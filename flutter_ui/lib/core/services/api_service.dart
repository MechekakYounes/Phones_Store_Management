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
        headers: ApiConfig.defaultHeaders(),
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
        headers: ApiConfig.defaultHeaders(),
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

  /// Get all buy phones (inventory)
  Future<Map<String, dynamic>> getBuyPhones({
    String? search,
    String? status,
    String? condition,
    int? brandId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/buy-phones').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status,
          if (condition != null) 'condition': condition,
          if (brandId != null) 'brand_id': brandId.toString(),
        },
      );

      final headers = ApiConfig.currentAuthHeaders();

      final response = await _client.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('not authenticated') || 
          e.toString().contains('User not authenticated')) {
        throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
      }
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Add a new phone purchase entry
  Future<Map<String, dynamic>> addBuyPhone({
    required Map<String, dynamic> productdata,
    }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/buy-phones');

      // Get latest token from AuthService
      final headers = ApiConfig.currentAuthHeaders();

      // Build request body with only the fields that exist
      final requestBody = <String, dynamic>{
        'seller_name': productdata['seller_name'],
        'seller_phone': productdata['seller_phone'] ?? '',
        'brand_id': productdata['brand_id'],
        'model': productdata['model'],
        'color': productdata['color'],
        'storage': productdata['storage'],
        'imei': productdata['imei'],
        'condition': productdata['condition'],
        'buy_price': productdata['buy_price'],
        'resell_price': productdata['resell_price'],
        'received_by': productdata['received_by'],
      };

      // Add optional fields only if they exist and are not null
      if (productdata['received_date'] != null) {
        requestBody['received_date'] = productdata['received_date'];
      }
      if (productdata['notes'] != null) {
        requestBody['notes'] = productdata['notes'];
      }
      if (productdata['issues'] != null) {
        requestBody['issues'] = productdata['issues'];
      }

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('not authenticated') || 
          e.toString().contains('User not authenticated')) {
        throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
      }
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Sell a phone
  Future<Map<String, dynamic>> sellPhone({
    required String id,
    required double soldPrice,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/buy-phones/$id/sell');
      final headers = ApiConfig.currentAuthHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({
          'sold_price': soldPrice,
        }),
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    }
    catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('not authenticated') || 
          e.toString().contains('User not authenticated')) {
        throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
      }
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