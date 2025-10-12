import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'current_user';

  /// Guarda los datos del usuario actual
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  /// Obtiene los datos del usuario actual
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    }
    
    return null;
  }

  /// Actualiza la foto de perfil del usuario
  static Future<void> updateProfileImage(String imagePath) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = user.copyWith(profileImage: imagePath);
      await saveUser(updatedUser);
    }
  }
  
  /// Actualiza los datos del perfil del usuario
  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? carnetNumber,
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
        userType: userType,
      );
      await saveUser(updatedUser);
    }
  }
  
  /// Actualiza el nivel de membresía
  static Future<void> updateMembershipLevel(String level) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = user.copyWith(membershipLevel: level);
      await saveUser(updatedUser);
    }
  }

  /// Limpia los datos del usuario (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Verifica si hay un usuario logueado
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}
