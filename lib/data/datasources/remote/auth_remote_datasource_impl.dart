import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/common/result.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return Result.failure(error: 'Login dibatalkan oleh pengguna.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final firebase_auth.UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Result.failure(error: 'User data is null after sign-in.');
      }

      return Result.success(data: UserModel.fromFirebaseUser(userCredential.user!));
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      return Result.success(
        data: firebaseUser != null ? UserModel.fromFirebaseUser(firebaseUser) : null,
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }
}