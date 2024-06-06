import 'package:flutter/material.dart';
import '../utils/google_sign_in.dart';
import 'home_page.dart';
import 'signup_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginSignupPage extends StatelessWidget {
  final GoogleSignInProvider _googleSignInProvider = GoogleSignInProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login / Signup'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // Rounded edges
                  child: Image.asset(
                    'assets/shopit_logo.png',
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.width * 0.3,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'ShopIt',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 100), // Increased space
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0), // Less padding
                margin: EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create an account',
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0), // Less padding
                margin: EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log in to an existing account',
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40), // Increased space
            ElevatedButton.icon(
              onPressed: () async {
                var googleSignInData =
                    await _googleSignInProvider.signInWithGoogle();
                if (googleSignInData != null) {
                  String? email = googleSignInData['email'];
                  bool exists = await _googleSignInProvider.userExists(email!);
                  if (exists) {
                    final AuthCredential credential =
                        GoogleAuthProvider.credential(
                      accessToken: googleSignInData['accessToken'],
                      idToken: googleSignInData['idToken'],
                    );

                    await FirebaseAuth.instance
                        .signInWithCredential(credential);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(initialIndex: 3)),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpPage(email: email),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Google sign-in failed. Please try again.')),
                  );
                }
              },
              icon: Icon(Icons.login, color: Colors.white),
              label: Text('Log in with Google'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))
              ),
            ),
          ],
        ),
      ),
    );
  }
}
