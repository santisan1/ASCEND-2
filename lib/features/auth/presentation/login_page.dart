import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../domain/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true; // true = login, false = registro

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackbar(authProvider.errorMessage!);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackbar(authProvider.errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu email y te enviaremos un link para resetear tu contraseña',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                Navigator.pop(context);
                _showErrorSnackbar('Ingresa un email válido');
                return;
              }

              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.resetPassword(
                emailController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email enviado. Revisa tu bandeja de entrada',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (authProvider.errorMessage != null) {
                  _showErrorSnackbar(authProvider.errorMessage!);
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LoadingOverlay(
          isLoading: authProvider.status == AuthStatus.authenticating,
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo/Titulo
                      _buildHeader(),

                      const SizedBox(height: 48),

                      // Campos de formulario
                      _buildForm(),

                      const SizedBox(height: 24),

                      // Botón principal
                      PrimaryButton(
                        text: _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        onPressed: _submit,
                        type: ButtonType.gradient,
                      ),

                      if (_isLogin) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Divider
                      _buildDivider(),

                      const SizedBox(height: 32),

                      // Google Sign-In
                      _buildGoogleButton(),

                      const SizedBox(height: 32),

                      // Toggle Login/Registro
                      _buildToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.trending_up, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'ASCEND',
          style: AppTextStyles.h1.copyWith(color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Bienvenido de vuelta' : 'Comienza tu ascenso',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'tu@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu email';
            }
            if (!value.contains('@')) {
              return 'Ingresa un email válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          labelText: 'Contraseña',
          hintText: '••••••••',
          obscureText: true,
          prefixIcon: Icons.lock_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu contraseña';
            }
            if (!_isLogin && value.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.dividerDark)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O continuar con',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryDark,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.dividerDark)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _signInWithGoogle,
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.g_mobiledata, size: 24);
        },
      ),
      label: const Text('Google'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLogin ? 'Regístrate' : 'Inicia sesión',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
