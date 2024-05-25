import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: user == null
          ? buildNonSignedIn(context)
          : buildSignedIn(context, user),
    );
  }

  Widget buildNonSignedIn(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/shopit_logo.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Icon(Icons.account_circle, size: 100, color: Colors.purple),
          SizedBox(height: 10),
          Text(
            'Log in or sign up to order online and participate in the bonus program',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.purple,
                ),
                child: Text('Log In'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.purple,
                ),
                child: Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSignedIn(BuildContext context, User user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/shopit_logo.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.account_circle, size: 50, color: Colors.purple),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My profile',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.email ?? '', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          buildProfileOption(Icons.update, 'Purchase history'),
          buildProfileOption(Icons.loyalty, 'Bonus program'),
          buildProfileOption(Icons.notifications, 'Notifications'),
          buildProfileOption(Icons.manage_accounts, 'Manage account'),
          buildProfileOption(Icons.logout, 'Logout', onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }),
        ],
      ),
    );
  }

  Widget buildProfileOption(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric( vertical: 18.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 239, 244), // Very light pink background
          ),
          child: Row(
            children: [
              SizedBox(width: 15),
              Icon(icon, color: Colors.purple),
              SizedBox(width: 22),
              Text(text, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
