import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import '../utils/cart_manager.dart';
import '../utils/barcode_scan.dart';
import 'home_page.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, Map<String, dynamic>> cartDetails = {};
  bool isLoading = true;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    loadCartDetails();
  }

  Future<void> loadCartDetails() async {
    setState(() {
      isLoading = true;
    });

    Map<String, int> cartItems = CartManager.getCartItems();
    if (cartItems.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final conn = await Connection.open(
      Endpoint(
        host: 'shopit-db.cjgagme48oci.eu-north-1.rds.amazonaws.com',
        database: 'clever_shop',
        username: 'master',
        password: 'password',
      ),
      settings: ConnectionSettings(sslMode: SslMode.require),
    );

    try {
      for (String productId in cartItems.keys) {
        var result = await conn.execute(Sql.named(
              'SELECT "productName", "price" FROM public."Product" WHERE "productId" = @productId')
          ,
          parameters: {'productId': productId},
        );

        if (result.isNotEmpty) {
          cartDetails[productId] = {
            'name': result.first[0],
            'price': double.parse(result.first[1].toString()),
            'quantity': cartItems[productId]!,
          };
        }
      }
      setState(() {
        totalPrice = CartManager.getTotalPrice(
          cartDetails.map((key, value) => MapEntry(key, value['price'])),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart details: ${e.toString()}')),
      );
    } finally {
      await conn.close();
      setState(() {
        isLoading = false;
      });
    }
  }

  void startCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
          sandboxMode: true,
          clientId: "AXi6aZh0nn5BZMhx37_ZOC69Ws9ZB6Zaps9Wjk-SOnIUCgsM1fywwbTuROKcf1LrMv1G9cwtcKh-ZtLf",
          secretKey: "EIwYNLrgFlzB7arvGLaBDmZMpWcRS0Ygq0sfr2ErYffwPdd6uOslY50laUxER9DdJ-cQ5nGhJPtmMMYV",
          returnURL: "com.example.shopit",
          cancelURL: "com.example.shopit",
          transactions: [
            {
              "amount": {
                "total": totalPrice.toStringAsFixed(2),
                "currency": "USD",
                "details": {
                  "subtotal": totalPrice.toStringAsFixed(2),
                  "shipping": '0',
                  "shipping_discount": 0
                }
              },
              "description": "Purchase from ShopIt",
              "item_list": {
                "items": cartDetails.entries.map((entry) {
                  return {
                    "name": entry.value['name'],
                    "quantity": entry.value['quantity'],
                    "price": entry.value['price'].toStringAsFixed(2),
                    "currency": "USD"
                  };
                }).toList(),
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Successful!')),
            );
            print("onSuccess: $params");
            // Clear the cart or update order status as needed
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Error: $error')),
            );
            print("onError: $error");
          },
          onCancel: (params) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Cancelled')),
            );
            print('cancelled: $params');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Cart',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: cartDetails.isEmpty ? buildEmptyCart() : buildCartItems(),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text('The cart is empty', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text(
            'To fill it you can scan items at store or add from the catalogue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text('Scan', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  BarcodeScanService.scanBarcode(context, loadCartDetails);
                },
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Add', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage(initialIndex: 1)),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('0\$',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartItems() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cartDetails.length,
            itemBuilder: (context, index) {
              String productId = cartDetails.keys.elementAt(index);
              Map<String, dynamic> item = cartDetails[productId]!;

              return Column(
                children: [
                  Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/placeholder.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['name'],
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      CartManager.removeItem(productId);
                                      cartDetails.remove(productId);
                                    });
                                  },
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          CartManager.removeItem(productId);
                                          if (CartManager.getCartItems()[
                                                      productId] ==
                                                  null ||
                                              CartManager.getCartItems()[
                                                      productId]! <=
                                                  0) {
                                            cartDetails.remove(productId);
                                          }
                                          loadCartDetails(); // Refresh cart details
                                        });
                                      },
                                    ),
                                    Text(item['quantity'].toString()),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          CartManager.addItem(productId);
                                          loadCartDetails(); // Refresh cart details
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: startCheckout,
            child: Text('Checkout', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
