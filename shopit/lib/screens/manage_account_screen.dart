import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';
import '../utils/db_utils.dart';
import 'change_email_screen.dart';
import 'home_page.dart';
import 'change_password_screen.dart';
import 'change_language_screen.dart';
import 'delete_account_screen.dart';
class ManageAccountScreen extends StatefulWidget {
  @override
  _ManageAccountScreenState createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserDetails();
  }

  void loadUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      var result = await conn.execute(
        Sql.named(
            'SELECT "userName", "userPhoneNumber" FROM public."User" WHERE "userId" = @userId'),
        parameters: {'userId': user.uid},
      );

      if (result.isNotEmpty) {
        setState(() {
          firstNameController.text = result.first[0]?.toString().split(' ')?.first ?? "";
          lastNameController.text = result.first[0]?.toString().split(' ')?.last ?? "";
          phoneController.text = result.first[1] as String? ?? "";
        });
      }
      await conn.close();
    }
  }

  void saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      await conn.execute(
        Sql.named(
            'UPDATE public."User" SET "userName" = @userName, "userPhoneNumber" = @userPhoneNumber WHERE "userId" = @userId'),
        parameters: {
          'userId': user.uid,
          'userName': '${firstNameController.text} ${lastNameController.text}',
          'userPhoneNumber': phoneController.text,
        },
      );
      await conn.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully!')),
      );
    }
  }

  void deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Account'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Personal data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'First name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last name'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800]),
                onPressed: saveChanges,
                child:
                    Text('Save changes', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 20),
              Text('Account data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              buildAccountOption(Icons.mail, 'Change email', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangeEmailScreen()),
                );
              }),
              buildAccountOption(Icons.lock, 'Change password', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              }),
              buildAccountOption(Icons.language, 'Change language', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangeLanguageScreen()),
                );
              }),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800]),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DeleteAccountScreen()),
                  );
                },
                child: Text('Delete account',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAccountOption(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.pink[800]),
            SizedBox(width: 16),
            Expanded(child: Text(text)),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
