import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Dynamic base URL selection based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; // For web
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8000"; // For Android emulator
    } else if (Platform.isIOS) {
      return "http://localhost:8000"; // For iOS simulator
    } else {
      // For Windows/macOS/Linux desktop apps
      return "http://127.0.0.1:8000";
    }
  }
  
  // API endpoints
  static const String registerEndpoint = "/auth/register";
  static const String loginEndpoint = "/auth/login";
  static const String incidentsEndpoint = "/incidents";
  static const String uploadEndpoint = "/incidents";  // Single file endpoint
  static const String multiUploadEndpoint = "/incidents/multiple";  // Multiple files endpoint
  static const String livestreamEndpoint = "/incidents/livestream";  // Livestream endpoint
  
  // Shared preferences keys
  static const String userIdKey = "user_id";
  static const String userEmailKey = "user_email";
  static const String isLoggedInKey = "is_logged_in";
}