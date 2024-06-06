import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';
import '../utils/db_utils.dart';
import 'home_page.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  final String? email;

  SignUpPage({this.email});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  Future<void> _signUpUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final conn = await DatabaseUtils.connect();
      await conn.execute(Sql.named(
        'INSERT INTO public."User"("userId", "userEmail", "userName", "userPassword", "userPhoneNumber") VALUES (@userId, @userEmail, @userName, @userPassword, @userPhoneNumber)'),
        parameters: {
          'userId': userCredential.user?.uid,
          'userEmail': _emailController.text,
          'userName': '${_surnameController.text} ${_nameController.text}',
          'userPassword':
              sha256.convert(utf8.encode(_passwordController.text)).toString(),
          'userPhoneNumber': _phoneController.text,
        },
      );
      await conn.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                initialIndex:
                    3)), // Navigate to the HomePage on successful signup
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed. Please try again.')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Enter your data', style: TextStyle(fontSize: 24)),
                    Divider(),
                    Text(
                        'Sign up to have access to the bonus program and be able to order with delivery',
                        style: TextStyle(color: Colors.grey)),
                    TextField(
                      controller: _surnameController,
                      decoration: InputDecoration(labelText: 'Surname'),
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      readOnly: widget.email !=
                          null, // Make the email field read-only if pre-filled
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Mobile phone'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signUpUser,
                      child: Text('Sign Up'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.pink[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
