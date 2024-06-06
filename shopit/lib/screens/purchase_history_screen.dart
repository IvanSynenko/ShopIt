// screens/purchase_history_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';
import '../utils/db_utils.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  @override
  _PurchaseHistoryScreenState createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<Map<String, dynamic>> purchaseHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPurchaseHistory();
  }

  Future<void> loadPurchaseHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conn = await DatabaseUtils.connect();
    try {
      var result = await conn.execute(
        Sql.named(
            'SELECT "Order"."orderId", "Order"."orderDate", "OrderProductQuantity"."productQuantity", "Product"."productName" '
            'FROM public."Order" '
            'INNER JOIN public."OrderProductQuantity" ON "Order"."orderId" = "OrderProductQuantity"."orderProductId" '
            'INNER JOIN public."Product" ON "OrderProductQuantity"."orderProductQuantityProductId" = "Product"."productId" '
            'WHERE "Order"."userOrderId" = @userId'),
        parameters: {'userId': user.uid},
      );

      setState(() {
        purchaseHistory = result.map((row) {
          return {
            'orderId': row[0],
            'orderDate': row[1],
            'productQuantity': row[2],
            'productName': row[3],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading purchase history: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase history'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : purchaseHistory.isEmpty
              ? Center(child: Text('Your purchase history is empty'))
              : ListView.builder(
                  itemCount: purchaseHistory.length,
                  itemBuilder: (context, index) {
                    var item = purchaseHistory[index];
                    return ListTile(
                      title: Text(item['productName']),
                      subtitle: Text('Quantity: ${item['productQuantity']}'),
                      trailing: Text(item['orderDate'].toString()),
                    );
                  },
                ),
    );
  }
}
