import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  
  // User data
  Map<String, dynamic>? _user;
  String? _token;
  List<String>? _permissions;
  String? _roleName;
  
  // Getters
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  List<String>? get permissions => _permissions;
  String? get roleName => _roleName;
  bool get isLoggedIn => _token != null;
  
  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _permissionsKey = 'user_permissions';
  static const String _roleNameKey = 'user_role_name';

  /// Initialize auth service
  Future<void> init() async {
    await _loadFromStorage();
  }

  /// Load data from SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    _token = prefs.getString(_tokenKey);
    final userString = prefs.getString(_userKey);
    final permissionsString = prefs.getString(_permissionsKey);
    _roleName = prefs.getString(_roleNameKey);
    
    if (userString != null) {
      _user = Map<String, dynamic>.from(json.decode(userString));
    }
    
    if (permissionsString != null) {
      _permissions = List<String>.from(json.decode(permissionsString));
    }
    
    notifyListeners();
  }

  /// Save data to SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    
    if (_user != null) {
      await prefs.setString(_userKey, json.encode(_user));
    }
    
    if (_permissions != null) {
      await prefs.setString(_permissionsKey, json.encode(_permissions));
    }
    
    if (_roleName != null) {
      await prefs.setString(_roleNameKey, _roleName!);
    }
  }

  /// Clear all stored data
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_roleNameKey);
    
    _user = null;
    _token = null;
    _permissions = null;
    _roleName = null;
    
    notifyListeners();
  }

  /// Login with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );
      
      if (response['success'] == true) {
        final data = response['data'];
        
        _token = data['token'];
        _user = Map<String, dynamic>.from(data['user']);
        _permissions = List<String>.from(data['permissions'] ?? []);
        _roleName = data['role_name'];
        
        await _saveToStorage();
        notifyListeners();
      } else {
        throw ApiException(message: response['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      if (_token != null) {
        await _apiService.logout(_token!);
      }
      
      await _clearStorage();
      notifyListeners();
      return true;
    } catch (e) {
      print('Logout error: $e');
      // Even if API logout fails, clear local data
      await _clearStorage();
      notifyListeners();
      return true;
    }
  }
  /// Get current user from API (refresh)
  Future<void> refreshUser() async {
    if (_token == null) return;
    
    try {
      final response = await _apiService.getCurrentUser(_token!);
      
      if (response['success'] == true) {
        final data = response['data'];
        
        _user = Map<String, dynamic>.from(data['user']);
        _permissions = List<String>.from(data['permissions'] ?? []);
        _roleName = data['role_name'];
        
        await _saveToStorage();
        notifyListeners();
      }
    } catch (e) {
      print('Failed to refresh user: $e');
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return _permissions?.contains(permission) ?? false;
  }

  /// Check if user is super admin
  bool isSuperAdmin() {
    return _user?['role'] == 'super_admin';
  }

  /// Check if user is admin
  bool isAdmin() {
    return _user?['role'] == 'admin';
  }

  /// Check if user is seller
  bool isSeller() {
    return _user?['role'] == 'seller';
  }

  /// Check if user is technician
  bool isTechnician() {
    return _user?['role'] == 'technician';
  }

  /// Check if user is inventory manager
  bool isInventory() {
    return _user?['role'] == 'inventory';
  }

  /// Get user's display name
  String getDisplayName() {
    return _user?['name'] ?? 'User';
  }

  /// Get user's username
  String getUsername() {
    return _user?['username'] ?? '';
  }

  /// Get user's phone
  String getPhone() {
    return _user?['phone'] ?? '';
  }
}