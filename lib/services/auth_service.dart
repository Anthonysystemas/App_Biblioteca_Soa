import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Para detectar la plataforma
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 🎯 CONFIGURACIÓN AUTOMÁTICA DE URL SEGÚN PLATAFORMA
  static String get baseUrl {
    if (kIsWeb) {
      // Web (Chrome, Firefox, etc.)
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Android
      return 'http://10.0.2.2:8000'; // Para emulador
      // return 'http://192.168.1.XXX:8000'; // Para dispositivo físico - cambiar XXX por tu IP
    } else if (Platform.isIOS) {
      // iOS
      return 'http://localhost:8000'; // Simulador iOS
      // return 'http://192.168.1.XXX:8000'; // Para dispositivo físico - cambiar XXX por tu IP
    } else {
      // Desktop (Windows, macOS, Linux)
      return 'http://localhost:8000';
    }
  }
  
  // 🔧 MÉTODO PARA CONFIGURAR IP MANUALMENTE (dispositivos físicos)
  static String? _customIp;
  
  static void setCustomIP(String ip) {
    _customIp = ip;
  }
  
  static String get effectiveBaseUrl {
    if (_customIp != null) {
      return 'http://$_customIp:8000';
    }
    return baseUrl;
  }

  // Guardar token en SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Eliminar token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // LOGIN
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = effectiveBaseUrl;
    print('🔐 Intentando login con: $username');
    print('📡 URL: $url/login');
    print('🖥️ Plataforma: ${_getPlatformName()}');
    
    try {
      final response = await http.post(
        Uri.parse('$url/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['access_token'] != null) {
          await _saveToken(data['access_token']);
          print('💾 Token guardado: ${data['access_token']}');
        }
        
        return {
          'success': true,
          'data': {
            'token': data['access_token'],
            'user_id': data['user_id'],
            'username': data['username'],
          },
          'message': 'Login exitoso'
        };
        
      } else if (response.statusCode == 401) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Credenciales incorrectas';
          
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
          
          print('❌ Error 401: $errorMessage');
          
          return {
            'success': false,
            'message': errorMessage,
            'error': errorData
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Credenciales incorrectas',
            'error': response.body
          };
        }
        
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Datos inválidos';
          
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
          
          print('❌ Error 400: $errorMessage');
          
          return {
            'success': false,
            'message': errorMessage,
            'error': errorData
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Datos inválidos',
            'error': response.body
          };
        }
        
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode})',
          'error': response.body
        };
      }
      
    } catch (e) {
      print('🚨 Excepción en login: $e');
      
      return {
        'success': false,
        'message': 'Error de conexión: No se pudo conectar al servidor.\n'
                  'URL: $url\n'
                  'Plataforma: ${_getPlatformName()}\n'
                  '${_getConnectionAdvice()}'
      };
    }
  }
  
  // REGISTER
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = effectiveBaseUrl;
    print('📝 Intentando registro con: $username, $email');
    print('📡 URL: $url/register');
    
    try {
      final response = await http.post(
        Uri.parse('$url/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': {
            'user_id': data['user_id'],
            'message': data['message'],
          },
          'message': 'Registro exitoso'
        };
        
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Usuario ya existe o datos inválidos';
          
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
          
          print('❌ Error 400: $errorMessage');
          
          return {
            'success': false,
            'message': errorMessage,
            'error': errorData
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Usuario ya existe o datos inválidos',
            'error': response.body
          };
        }
        
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode})',
          'error': response.body
        };
      }
      
    } catch (e) {
      print('🚨 Excepción en registro: $e');
      
      return {
        'success': false,
        'message': 'Error de conexión: No se pudo conectar al servidor.\n'
                  'URL: $url\n'
                  'Plataforma: ${_getPlatformName()}\n'
                  '${_getConnectionAdvice()}'
      };
    }
  }
  
  // VERIFY TOKEN
  Future<Map<String, dynamic>> verifyToken([String? token]) async {
    try {
      String? authToken = token ?? await getToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No hay token disponible'
        };
      }
      
      final url = effectiveBaseUrl;
      final response = await http.post(
        Uri.parse('$url/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': authToken,
        }),
      );
      
      print('📊 Verify Status Code: ${response.statusCode}');
      print('📋 Verify Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': data,
          'valid': data['valid'] ?? false,
          'user': data['user'],
          'user_id': data['user_id'],
        };
        
      } else if (response.statusCode == 401) {
        print('🔑 Token inválido, eliminando...');
        await removeToken();
        
        return {
          'success': false,
          'valid': false,
          'message': 'Token inválido o expirado'
        };
        
      } else {
        return {
          'success': false,
          'valid': false,
          'message': 'Error de verificación del servidor'
        };
      }
      
    } catch (e) {
      print('🚨 Excepción en verify: $e');
      
      return {
        'success': false,
        'valid': false,
        'message': 'Error de verificación: $e'
      };
    }
  }
  
  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final result = await verifyToken();
    return result['success'] == true && result['valid'] == true;
  }
  
  // Logout
  Future<void> logout() async {
    print('🚪 Cerrando sesión...');
    await removeToken();
  }
  
  // Obtener información del usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final result = await verifyToken();
    if (result['success'] == true && result['valid'] == true) {
      return {
        'username': result['user'],
        'user_id': result['user_id'],
      };
    }
    return null;
  }

  // 🧪 MÉTODO MEJORADO PARA PROBAR CONEXIÓN
  Future<Map<String, dynamic>> testConnection() async {
    final url = effectiveBaseUrl;
    print('🌐 Probando conexión con: $url');
    print('🖥️ Plataforma: ${_getPlatformName()}');
    
    try {
      final response = await http.get(
        Uri.parse('$url/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      print('📊 Test Status Code: ${response.statusCode}');
      print('📋 Test Response: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final isOk = data['status'] == 'ok';
          
          return {
            'success': isOk,
            'message': isOk ? 'Conexión exitosa' : 'Servidor responde pero con error',
            'data': data
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Conexión exitosa (respuesta no JSON)',
            'data': response.body
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Servidor responde con error ${response.statusCode}',
          'data': response.body
        };
      }
    } catch (e) {
      print('🚨 Error de conexión: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor.\n'
                  'URL: $url\n'
                  'Error: $e\n'
                  '${_getConnectionAdvice()}'
      };
    }
  }
  
  // Método auxiliar para mostrar información de plataforma
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Desconocida';
  }
  
  // Método auxiliar para dar consejos de conexión
  String _getConnectionAdvice() {
    if (kIsWeb) {
      return 'Verifica que tu API esté corriendo en localhost:8000';
    } else if (Platform.isAndroid) {
      return 'Para emulador Android usa 10.0.2.2:8000\n'
             'Para dispositivo físico usa tu IP local (192.168.1.XXX:8000)';
    } else if (Platform.isIOS) {
      return 'Para simulador iOS usa localhost:8000\n'
             'Para dispositivo físico usa tu IP local (192.168.1.XXX:8000)';
    } else {
      return 'Verifica que tu API esté corriendo en localhost:8000';
    }
  }
  
  // Método auxiliar para debug
  Future<void> debugShowToken() async {
    final token = await getToken();
    print('🔍 Token actual: ${token ?? "No hay token"}');
  }
  
  // Método auxiliar para obtener headers con autenticación
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}