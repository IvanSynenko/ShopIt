import 'package:flutter/material.dart';
import '../utils/cart_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';
import '../utils/db_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic> product = {};
  bool isLoading = true;
  bool isAvailable = false;

  @override
  void initState() {
    super.initState();
    loadProductDetails();
  }

  Future<void> loadProductDetails() async {
    final conn = await DatabaseUtils.connect();
    var result = await conn.execute(
      Sql.named(
          'SELECT "productName", "price", "productDescription" FROM public."Product" WHERE "productId" = @productId'),
      parameters: {
        'productId': widget.productId,
      },
    );

    if (result.isNotEmpty) {
      product = {
        'productName': result.first[0],
        'price': result.first[1],
        'productDescription': result.first[2],
      };
    }

    // Check availability (simplified example)
    var availabilityResult = await conn.execute(
      Sql.named(
          'SELECT COUNT(*) FROM public."ProductShop" WHERE "productID" = @productId AND "productQuantity" > 0'),
      parameters: {
        'productId': widget.productId,
      },
    );

    if (availabilityResult.isNotEmpty && (availabilityResult.first[0] as int) > 0) {
      isAvailable = true;
    }

    await conn.close();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/placeholder.png', // Replace with actual image
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20),
                  Text(
                    product['productName'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\$${product['price']}',
                    style: TextStyle(fontSize: 22, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    isAvailable
                        ? 'Available'
                        : 'Not available in stores near you',
                    style: TextStyle(
                        fontSize: 18,
                        color: isAvailable ? Colors.green : Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (isAvailable)
                    ElevatedButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'You need to be logged in to add items to the online cart')),
                          );
                          return;
                        }
                        await CartManager.addItem(widget.productId,
                            isLocal: false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to cart')),
                        );
                      },
                      child: Text('Add to the cart',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[800],
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
