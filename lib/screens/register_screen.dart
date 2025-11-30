import 'package:flutter/material.dart';
import '../widgets/background_painters.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universidadController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: CustomPaint(
        painter: RegisterBackgroundPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Crear\nCuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre Completo',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'Ingresa tu nombre completo',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Correo Electrónico',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'correo@ejemplo.com',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'DNI o Carnet',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _dniController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'Ingresa tu DNI o carnet',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Número Celular',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'Ingresa tu número celular',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Universidad',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _universidadController,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'Ingresa tu universidad',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintText: 'Crea una contraseña segura',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = User(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                carnetNumber: _dniController.text.trim(),
                                phone: _phoneController.text.trim(),
                                universidad: _universidadController.text.trim(),
                              );
                              
                              final navigator = Navigator.of(context);
                              
                              await UserService.saveUser(user);
                              
                              if (!mounted) return;
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: const Color(0xFF1976D2).withValues(alpha: 0.3),
                            ),
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Ya tengo cuenta',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}