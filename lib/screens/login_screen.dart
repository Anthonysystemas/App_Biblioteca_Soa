// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../widgets/background_painters.dart'; // Importar los painters
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(); // Cambio: username en lugar de email
  final _passwordController = TextEditingController();
  
  bool _isLoading = false; // Estado de carga
  String? _errorMessage; // Mensaje de error

  // Método para manejar el login
  Future<void> _handleLogin() async {
    // Validar campos vacíos
    if (_usernameController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular un pequeño delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Login simple - cualquier usuario y contraseña permite acceso
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomPaint(
        painter: LoginBackgroundPainter(), // Usar el painter
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header con título
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Welcome\nBack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Espaciador
                  const Spacer(),

                  // Formulario
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        // Mostrar mensaje de error si existe
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, 
                                     color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Campo Username (cambio de Email a Username)
                        TextField(
                          controller: _usernameController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Username', // Cambio: tu API usa username
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            errorText: _errorMessage != null && 
                                      _usernameController.text.isEmpty 
                                      ? 'Username requerido' : null,
                          ),
                          onChanged: (value) {
                            // Limpiar error cuando el usuario empiece a escribir
                            if (_errorMessage != null) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Campo Password
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            errorText: _errorMessage != null && 
                                      _passwordController.text.isEmpty 
                                      ? 'Password requerido' : null,
                          ),
                          onChanged: (value) {
                            // Limpiar error cuando el usuario empiece a escribir
                            if (_errorMessage != null) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                          onSubmitted: (value) {
                            // Permitir login con Enter
                            if (!_isLoading) {
                              _handleLogin();
                            }
                          },
                        ),
                        const SizedBox(height: 30),

                        // Botón Login con estado de carga
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin, // Deshabilitar durante carga
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4299E1),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Botón Register
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            // Navegar al RegisterScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: _isLoading ? Colors.grey : Colors.black54
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: "Register",
                                  style: TextStyle(
                                    color: _isLoading ? Colors.grey : const Color(0xFF4299E1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}