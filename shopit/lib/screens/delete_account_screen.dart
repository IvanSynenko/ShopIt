// screens/delete_account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_utils.dart';
import 'home_page.dart';
import 'package:postgres/postgres.dart';
class DeleteAccountScreen extends StatefulWidget {
  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool isSure = false;
  bool isLoading = false;

  Future<void> deleteUserAccount() async {
    setState(() {
      isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();

      try {
        // Update user-related data in the Order table
        await conn.execute(
          Sql.named(
              'UPDATE public."Order" SET "receiver" = @deleted, "receiverPhone" = @deleted, "userOrderId" = @deleted WHERE "userOrderId" = @userId'),
          parameters: {
            'userId': user.uid,
            'deleted': 'deleted',
          },
        );

        // Delete user's cart items from UsersProductQuantity table
        await conn.execute(
          Sql.named(
              'DELETE FROM public."UsersProductQuantity" WHERE "userId" = @userId'),
          parameters: {
            'userId': user.uid,
          },
        );

        // Delete user from User table
        await conn.execute(
          Sql.named('DELETE FROM public."User" WHERE "userId" = @userId'),
          parameters: {
            'userId': user.uid,
          },
        );

        // Delete user from Firebase
        await user.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.toString()}')),
        );
      } finally {
        await conn.close();
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Account'),
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
            CheckboxListTile(
              title: Text(
                'I am sure that I want to delete my ShopIt account and my purchase history. I refuse ShopIt to send me any notifications',
                style: TextStyle(fontSize: 16),
              ),
              value: isSure,
              onChanged: (bool? value) {
                setState(() {
                  isSure = value ?? false;
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
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: isSure && !isLoading
                    ? () async {
                        await deleteUserAccount();
                      }
                    : null,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Delete Account',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
