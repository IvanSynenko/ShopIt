// screens/change_email_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_utils.dart';
import 'package:postgres/postgres.dart';
class ChangeEmailScreen extends StatefulWidget {
  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final TextEditingController newEmailController = TextEditingController();
  String currentEmail = "";

  @override
  void initState() {
    super.initState();
    loadCurrentEmail();
  }

  void loadCurrentEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentEmail = user.email ?? "";
      });
    }
  }

  void changeEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateEmail(newEmailController.text);
        await updateEmailInDatabase(user.uid, newEmailController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating email: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> updateEmailInDatabase(String userId, String newEmail) async {
    final conn = await DatabaseUtils.connect();
    await conn.execute(
      Sql.named(
          'UPDATE public."User" SET "userEmail" = @newEmail WHERE "userId" = @userId'),
      parameters: {
        'userId': userId,
        'newEmail': newEmail,
      },
    );
    await conn.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Email'),
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
            Row(
              children: [
                Icon(Icons.mail, color: Colors.pink[800], size: 50),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your current email', style: TextStyle(fontSize: 18)),
                    Text(currentEmail, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('New email', style: TextStyle(fontSize: 18)),
            TextField(
              controller: newEmailController,
              decoration: InputDecoration(
                hintText: 'Input your new email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800]),
              onPressed: changeEmail,
              child:
                  Text('Save changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
