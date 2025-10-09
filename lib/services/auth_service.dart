import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. IMPORTAR O FIRESTORE

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance; // <-- 2. ADICIONAR A INSTÂNCIA DO FIRESTORE

  /// Stream para escutar mudanças no estado de autenticação (login/logout).
  Stream<User?> get user => _auth.authStateChanges();

  /// Realiza o login de um usuário com e-mail e senha.
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // É uma boa prática capturar exceções específicas para dar feedback melhor.
      print('Erro de login: ${e.message}');
      return null;
    }
  }

  /// **NOVO MÉTODO PARA CADASTRAR UM NOVO USUÁRIO**
  Future<User?> signUp(String name, String email, String password) async { // <-- MUDANÇA
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? newUser = result.user;

      if (newUser != null) {
        // Adiciona o campo 'name' ao criar o documento
        await _db.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': name, // <-- MUDANÇA
          'email': newUser.email,
          'role': 'funcionario',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return newUser;
    } on FirebaseAuthException catch (e) {
      print('Erro de cadastro: ${e.message}');
      return null;
    }
  }

  /// Realiza o logout do usuário atual.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}