import 'package:flutter_ui/core/services/auth_service.dart';

class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api'; // Use this for Android emulator
  static const Duration timeout = Duration(seconds: 30);

  // Default headers without token
  static Map<String, String> defaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  // Authenticated headers with token
  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders(),
      'Authorization': 'Bearer $token',
    };
  }

  // Helper to get headers with current token from AuthService
  static Map<String, String> currentAuthHeaders() {
    final token = AuthService().token;
    if (token == null) throw Exception('User not authenticated');
    return authHeaders(token);
  }
}
