import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reservas_service.dart';
import 'prestamos_service.dart';

class ExpirationCheckerService {
  static final ExpirationCheckerService _instance = ExpirationCheckerService._internal();
  factory ExpirationCheckerService() => _instance;
  ExpirationCheckerService._internal();

  Timer? _dailyTimer;
  static const String _lastCheckKey = 'last_expiration_check';

  Future<void> initialize() async {
    await _checkExpirations();

    _dailyTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      await _checkExpirations();
    });
    
    debugPrint('⏱️ MODO PRODUCCIÓN: Verificación cada 24 horas iniciada');
  }

  Future<void> _checkExpirations() async {
    try {
      final now = DateTime.now();
      debugPrint('🔍 Ejecutando verificaciones de expiración/vencimiento: ${now.toString()}');

      final prefs = await SharedPreferences.getInstance();

      await ReservasService.verificarReservasExpiradas();
      await PrestamosService.verificarPrestamosVencidos();
      await PrestamosService.notificarProximosAVencer();

      await prefs.setString(_lastCheckKey, now.toIso8601String());
      
      debugPrint('✅ Verificaciones completadas exitosamente');
    } catch (e) {
      debugPrint('❌ Error al ejecutar verificaciones: $e');
    }
  }

  Future<void> forceCheck() async {
    debugPrint('🔄 Forzando verificación manual...');
    await ReservasService.verificarReservasExpiradas();
    await PrestamosService.verificarPrestamosVencidos();
    await PrestamosService.notificarProximosAVencer();
    debugPrint('✅ Verificación manual completada');
  }

  void dispose() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    debugPrint('🛑 ExpirationCheckerService detenido');
  }
}