import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ui/core/config/api_config.dart';
import 'api_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final http.Client _client = http.Client();

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/dashboard/statistics');
      final headers = ApiConfig.currentAuthHeaders();

      final response = await _client.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final statusCode = response.statusCode;
      final responseBody = json.decode(response.body);

      if (statusCode >= 200 && statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          message: responseBody['message'] ?? 'Failed to load dashboard',
          statusCode: statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }
}
