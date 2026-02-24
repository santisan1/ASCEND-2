import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/firebase/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Escuchar cambios de autenticación
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    print('DEBUG: [1] Intentando cargar datos de usuario con UID: $uid');
    try {
      _user = await _authService.getUserFromFirestore(uid);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      print(
        'DEBUG: [3] Datos cargados exitosamente. Estableciendo status: authenticated',
      );
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ============ REGISTRO ============
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (_user != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'No se pudo crear la cuenta';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============ LOGIN CORREGIDO ============
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      // 1. Llama al servicio de autenticación (AuthService)
      final userModel = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userModel != null) {
        // 2. Si es exitoso, el listener de authStateChanges (en _init)
        //    DEBE ser quien llame a _loadUserData.
        //    Aquí, simplemente verificamos que el usuario esté en Firebase Auth.
        return true; // Si llegamos aquí, el usuario se autenticó.
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'No se pudo iniciar sesión';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();

      return false;
    }
  }

  // ============ LOGIN CON GOOGLE ============
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signInWithGoogle();

      if (_user != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============ LOGOUT ============
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ============ RECUPERAR CONTRASEÑA ============
  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
