import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _navigateToLogin();
  }

  void _initAnimations() {
    // Controller para el ícono (2 segundos)
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controller para el texto (1.5 segundos, empezar después de 0.5s)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller para el background (4 segundos total)
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Animación del ícono - escala con bounce
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    // Animación del ícono - rotación sutil
    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));

    // Animación del texto - opacidad
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Animación del texto - deslizamiento desde abajo
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    // Animación del background - cambio de color gradual
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFF667EEA),
      end: const Color(0xFF764BA2),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Animación de loading - rotación continua al final
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: const Interval(0.7, 1.0, curve: Curves.linear),
    ));
  }

  void _startAnimations() {
    // Iniciar animación del background inmediatamente
    _backgroundController.forward();
    
    // Iniciar animación del ícono después de 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconController.forward();
    });
    
    // Iniciar animación del texto después de 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundColorAnimation.value ?? const Color(0xFF667EEA),
                  _backgroundColorAnimation.value?.withOpacity(0.8) ?? 
                      const Color(0xFF764BA2).withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo/Ícono principal con animaciones
                  AnimatedBuilder(
                    animation: _iconController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _iconRotationAnimation.value,
                          child: Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.library_books,
                              size: screenWidth * 0.15,
                              color: const Color(0xFF667EEA),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Texto principal con animaciones
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'BiblioTeca',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.08,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Tu biblioteca digital',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // Indicador de carga con animación
                  AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _loadingAnimation.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Cargando tu biblioteca...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}