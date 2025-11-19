import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reservas_service.dart';
import 'prestamos_service.dart';

/// Servicio para verificar automáticamente expiración de reservas y vencimiento de préstamos
class ExpirationCheckerService {
  static final ExpirationCheckerService _instance = ExpirationCheckerService._internal();
  factory ExpirationCheckerService() => _instance;
  ExpirationCheckerService._internal();

  Timer? _dailyTimer;
  static const String _lastCheckKey = 'last_expiration_check';

  /// Inicializar el servicio y ejecutar verificación diaria
  Future<void> initialize() async {
    // Ejecutar verificación inmediata al iniciar
    await runChecks();

    // Configurar timer para ejecutar cada 24 horas
    _dailyTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      await runChecks();
    });

    debugPrint('✅ ExpirationCheckerService inicializado - Verificaciones diarias activas');
  }

  /// Ejecutar todas las verificaciones
  Future<void> runChecks() async {
    try {
      final now = DateTime.now();
      debugPrint('🔍 Ejecutando verificaciones de expiración/vencimiento: ${now.toString()}');

      // Verificar si ya se ejecutó hoy
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastCheckKey);
      
      if (lastCheckStr != null) {
        final lastCheck = DateTime.parse(lastCheckStr);
        final difference = now.difference(lastCheck);
        
        // Si ya se ejecutó hace menos de 12 horas, saltar
        if (difference.inHours < 12) {
          debugPrint('⏭️ Verificación ya ejecutada hace ${difference.inHours} horas. Saltando...');
          return;
        }
      }

      // Ejecutar verificaciones
      await ReservasService.verificarReservasExpiradas();
      await PrestamosService.verificarPrestamosVencidos();
      await PrestamosService.notificarProximosAVencer();

      // Guardar timestamp de última verificación
      await prefs.setString(_lastCheckKey, now.toIso8601String());
      
      debugPrint('✅ Verificaciones completadas exitosamente');
    } catch (e) {
      debugPrint('❌ Error al ejecutar verificaciones: $e');
    }
  }

  /// Forzar ejecución manual (útil para testing)
  Future<void> forceCheck() async {
    debugPrint('🔄 Forzando verificación manual...');
    await ReservasService.verificarReservasExpiradas();
    await PrestamosService.verificarPrestamosVencidos();
    await PrestamosService.notificarProximosAVencer();
    debugPrint('✅ Verificación manual completada');
  }

  /// Detener el servicio
  void dispose() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    debugPrint('🛑 ExpirationCheckerService detenido');
  }
}
