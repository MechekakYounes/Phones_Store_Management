
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  // use 'http://10.0.2.2:8000/' for Android emulator
  // Or '' for iOS simulator
  
  static const Duration timeout = Duration(seconds: 30);
  
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };
  
  static Map<String, String> authHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}