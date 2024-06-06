import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:postgres/postgres.dart';
import '../utils/db_utils.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    loadNotificationPreference();
    setupFirebaseMessaging();
  }

  Future<void> loadNotificationPreference() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      try {
        var result = await conn.execute(
          Sql.named(
              'SELECT "userNotification" FROM public."User" WHERE "userId" = @userId'),
          parameters: {'userId': user.uid},
        );

        if (result.isNotEmpty) {
          setState(() {
            notificationsEnabled = result.first[0] as bool;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error loading notification preference: ${e.toString()}')),
        );
      } finally {
        await conn.close();
      }
    }
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conn = await DatabaseUtils.connect();
      try {
        await conn.execute(
          Sql.named(
              'UPDATE public."User" SET "userNotification" = @enabled WHERE "userId" = @userId'),
          parameters: {'enabled': enabled, 'userId': user.uid},
        );
        setState(() {
          notificationsEnabled = enabled;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating notification preference: ${e.toString()}')),
        );
      } finally {
        await conn.close();
      }
    }
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((token) {
      print('FCM Token: $token');
      // Send the token to your server to subscribe the user to notifications
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.notification!.body ?? '')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications about our new propositions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Checkbox(
                  value: notificationsEnabled,
                  onChanged: (bool? value) {
                    if (value != null) {
                      updateNotificationPreference(value);
                    }
                  },
                ),
              ],
            ),
            Text(
              'Notifications about our latest propositions and hottest discounts can help you enhance your shopping experience',
              style: TextStyle(fontSize: 16),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
