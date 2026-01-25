// lib/core/providers/login_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_ui/core/services/auth_service.dart';

class LoginProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Success state
  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;
  
  /// Login method
  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.login(
        username: username.trim(),
        password: password,
      );
      
      _setSuccess(true);
    } catch (e) {
      _setError(e.toString());
      _setSuccess(false);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Clear error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Set error
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set success state
  void _setSuccess(bool success) {
    _isSuccess = success;
    notifyListeners();
  }
  
  /// Reset state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }
}