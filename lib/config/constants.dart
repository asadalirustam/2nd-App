import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'Expense Tracker Pro';

  // Base API URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.100.10:5001/api';
    } else if (Platform.isAndroid) {
      return 'http://192.168.100.10:5001/api'; // Android (Using adb reverse)
    } else {
      return 'http://192.168.100.10:5001/api'; // iOS / Desktop / Others
    }
  }

  // Base uploads url
  static String get uploadsUrl {
    if (kIsWeb) {
      return 'http://192.168.100.10:5001';
    } else if (Platform.isAndroid) {
      return 'http://192.168.100.10:5001';
    } else {
      return 'http://192.168.100.10:5001';
    }
  }

  // Categories
  static const List<String> categories = [
    'Food',
    'Shopping',
    'Bills',
    'Travel',
    'Education',
    'Entertainment',
    'Health',
    'Others',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Other',
  ];
}
