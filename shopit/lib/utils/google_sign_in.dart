import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:postgres/postgres.dart';
import 'db_utils.dart';

class GoogleSignInProvider {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, String?>?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // The user canceled the sign-in
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    return {
      'accessToken': googleAuth.accessToken,
      'idToken': googleAuth.idToken,
      'email': googleUser.email,
    };
  }

  Future<bool> userExists(String email) async {
    final conn = await DatabaseUtils.connect();
    var result = await conn.execute(Sql.named(
      'SELECT "userId" FROM public."User" WHERE "userEmail" = @userEmail'),
      parameters: {
        'userEmail': email,
      },
    );
    await conn.close();
    return result.isNotEmpty;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
