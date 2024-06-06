// screens/change_language_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_utils.dart';
import 'package:postgres/postgres.dart';
class ChangeLanguageScreen extends StatefulWidget {
  @override
  _ChangeLanguageScreenState createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  bool? userInterfaceLanguage;

  @override
  void initState() {
    super.initState();
    loadUserLanguagePreference();
  }

  void loadUserLanguagePreference() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      var result = await conn.execute(
        Sql.named(
            'SELECT "userInterfaceLanguage" FROM public."User" WHERE "userId" = @userId'),
        parameters: {'userId': user.uid},
      );

      if (result.isNotEmpty) {
        setState(() {
          userInterfaceLanguage = result.first[0] as bool;
        });
      }
      await conn.close();
    }
  }

  void changeLanguage(bool language) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      await conn.execute(
        Sql.named(
            'UPDATE public."User" SET "userInterfaceLanguage" = @language WHERE "userId" = @userId'),
        parameters: {
          'userId': user.uid,
          'language': language,
        },
      );
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Language'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioListTile<bool>(
              title: Text('English', style: TextStyle(fontSize: 18)),
              value: true,
              groupValue: userInterfaceLanguage,
              onChanged: (bool? value) {
                setState(() {
                  userInterfaceLanguage = value;
                });
              },
              activeColor: Colors.pink[800],
            ),
            RadioListTile<bool>(
              title: Text('Ukrainian', style: TextStyle(fontSize: 18)),
              value: false,
              groupValue: userInterfaceLanguage,
              onChanged: (bool? value) {
                setState(() {
                  userInterfaceLanguage = value;
                });
              },
              activeColor: Colors.pink[800],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[800],
                  padding: EdgeInsets.symmetric(vertical: 16.0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: () {
                  if (userInterfaceLanguage != null) {
                    changeLanguage(userInterfaceLanguage!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language changed successfully!')),
                    );
                  }
                },
                child: Text('Save changes',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
