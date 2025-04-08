import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // Save user session
  Future<void> saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.id != null) {
      await prefs.setInt(Constants.userIdKey, user.id!);
    }
    await prefs.setString(Constants.userEmailKey, user.email ?? '');
    await prefs.setBool(Constants.isLoggedInKey, true);
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isLoggedInKey) ?? false;
  }
  
  // Get current user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Constants.userIdKey);
  }
  
  // Get current user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.userEmailKey);
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    final id = await getUserId();
    final email = await getUserEmail();
    
    if (id != null && email != null) {
      return User(id: id, email: email);
    }
    
    return null;
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.userIdKey);
    await prefs.remove(Constants.userEmailKey);
    await prefs.setBool(Constants.isLoggedInKey, false);
  }
}