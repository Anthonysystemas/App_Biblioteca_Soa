import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'current_user';

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    }
    
    return null;
  }

  static Future<void> updateProfileImage(String imagePath) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = user.copyWith(profileImage: imagePath);
      await saveUser(updatedUser);
    }
  }
  
  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? carnetNumber,
    String? universidad,
    String? userType,
  }) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = user.copyWith(
        name: name,
        email: email,
        phone: phone,
        address: address,
        birthDate: birthDate,
        carnetNumber: carnetNumber,
        universidad: universidad,
        userType: userType,
      );
      await saveUser(updatedUser);
    }
  }
  
  static Future<void> updateMembershipLevel(String level) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = user.copyWith(membershipLevel: level);
      await saveUser(updatedUser);
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}