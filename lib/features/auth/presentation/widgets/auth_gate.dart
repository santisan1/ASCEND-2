// Archivo: lib/features/auth/presentation/widgets/auth_gate.dart
import 'package:ascend/features/auth/domain/auth_provider.dart';
import 'package:ascend/features/auth/presentation/login_page.dart';
import 'package:ascend/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchar los cambios de estado en el AuthProvider
    final authProvider = context.watch<AuthProvider>();

    // Decidir qué pantalla mostrar basado en el estado
    switch (authProvider.status) {
      case AuthStatus.authenticating:
      case AuthStatus.initial:
        // Muestra un spinner mientras Firebase comprueba el token (primera carga)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.unauthenticated:
        // Muestra el Login si no hay usuario o si el token expiró/falló
        return LoginPage();

      case AuthStatus.authenticated:
        // Muestra la página principal si ya está autenticado y los datos cargados
        return const HomePage();
    }
  }
}
