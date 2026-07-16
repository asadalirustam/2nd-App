import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'Expense Tracker Pro';

  // Base API URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api'; // Android Emulator
    } else {
      return 'http://localhost:5000/api'; // iOS / Desktop / Others
    }
  }

  // Base uploads url
  static String get uploadsUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
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
