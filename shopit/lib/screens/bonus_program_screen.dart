import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_utils.dart';
import 'package:postgres/postgres.dart';
class BonusProgramScreen extends StatefulWidget {
  @override
  _BonusProgramScreenState createState() => _BonusProgramScreenState();
}

class _BonusProgramScreenState extends State<BonusProgramScreen> {
  double userBonusAccount = 0.0;

  @override
  void initState() {
    super.initState();
    loadUserBonusAccount();
  }

  Future<void> loadUserBonusAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      var result = await conn.execute(
        Sql.named(
            'SELECT "userBonusAccount" FROM public."User" WHERE "userId" = @userId'),
        parameters: {'userId': user.uid},
      );

      if (result.isNotEmpty) {
        setState(() {
          userBonusAccount = double.parse(result.first[0].toString());
        });
      }
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonus program'),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.account_circle, size: 50, color: Colors.pink[800]),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My profile',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your bonus count:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userBonusAccount.toString(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Participation in the bonus program allows you to exchange your bonus points to real money at our stores:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                '100000 points = 1000\$\n'
                '10000 points = 60\$\n'
                '1000 points = 3\$',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
