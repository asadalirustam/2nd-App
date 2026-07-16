import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Auto Login Check
  Future<bool> tryAutoLogin() async {
    final hasToken = await _storage.containsKey(key: 'jwt_token');
    if (!hasToken) return false;

    _token = await _storage.read(key: 'jwt_token');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/user/profile');
      if (response.data['success'] == true) {
        _user = UserModel.fromJson(response.data['user']);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Auto login failed: $e');
      await logout();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register / Sign Up
  Future<void> signup(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        _token = response.data['token'];
        _user = UserModel.fromJson(response.data['user']);
        
        // Save token to secure storage
        await _storage.write(key: 'jwt_token', value: _token);
        _isAuthenticated = true;
      } else {
        throw response.data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        _token = response.data['token'];
        _user = UserModel.fromJson(response.data['user']);

        // Save token to secure storage
        await _storage.write(key: 'jwt_token', value: _token);
        _isAuthenticated = true;
      } else {
        throw response.data['message'] ?? 'Login failed';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot Password
  Future<String> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.data['success'] == true) {
        // Return reset code directly (since it's mocked on backend for ease of demo)
        return response.data['resetToken'] ?? '';
      } else {
        throw response.data['message'] ?? 'Failed to send reset code';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset Password
  Future<void> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/reset-password', data: {
        'email': email,
        'resetToken': code,
        'newPassword': newPassword,
      });

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Password reset failed';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Profile Name / Image
  Future<void> updateProfile({String? name, File? profileImage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fields = <String, dynamic>{};
      if (name != null) fields['name'] = name;

      final response = await _apiService.multipartRequest(
        path: '/user/profile',
        method: 'PUT',
        fields: fields,
        file: profileImage,
        fileFieldName: 'profileImage',
      );

      if (response.data['success'] == true) {
        _user = UserModel.fromJson(response.data['user']);
      } else {
        throw response.data['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change Password while Logged In
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/user/profile', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to change password';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.delete(key: 'jwt_token');
      _user = null;
      _token = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
