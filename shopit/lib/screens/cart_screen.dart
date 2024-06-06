import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/cart_manager.dart';
import '../utils/barcode_scan.dart';
import 'home_page.dart';
import 'configure_order_screen.dart';
import '../utils/db_utils.dart';

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

    User? user = FirebaseAuth.instance.currentUser;
    if(CartManager.getCartItems().isNotEmpty){
      await loadLocalCart();
    }else{
      if (user != null) {
      // Load online cart
      await loadOnlineCart(user.uid);
    }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadLocalCart() async {
    Map<String, int> cartItems = CartManager.getCartItems();
    if (cartItems.isEmpty) {
      return;
    }

    final conn = await DatabaseUtils.connect();

    try {
      for (String productId in cartItems.keys) {
        var result = await conn.execute(
          Sql.named(
              'SELECT "productName", "price" FROM public."Product" WHERE "productId" = @productId'),
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
    }
  }

  Future<void> loadOnlineCart(String userId) async {
    final conn = await DatabaseUtils.connect();

    try {
      var result = await conn.execute(
        Sql.named(
            'SELECT "productId", "productQuantity" FROM public."UsersProductQuantity" WHERE "userId" = @userId'),
        parameters: {'userId': userId},
      );

      for (var row in result) {
        String productId = row[0] as String;
        int quantity = row[1] as int;

        var productResult = await conn.execute(
          Sql.named(
              'SELECT "productName", "price" FROM public."Product" WHERE "productId" = @productId'),
          parameters: {'productId': productId},
        );

        if (productResult.isNotEmpty) {
          cartDetails[productId] = {
            'name': productResult.first[0],
            'price': double.parse(productResult.first[1].toString()),
            'quantity': quantity,
          };
        }
      }

      totalPrice = cartDetails.entries
          .map((entry) => entry.value['price'] * entry.value['quantity'])
          .fold(0.0, (prev, amount) => prev + amount);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading online cart details: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }

  void startPaypalCheckout(double totalPrice) async {
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? 'notregistered';
    String receiver = user?.displayName ?? 'notregistered';
    String receiverPhone = user?.phoneNumber ?? 'notregistered';

    final conn = await DatabaseUtils.connect();
    try {
      

      // Proceed with PayPal checkout
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => PaypalCheckoutView(
          sandboxMode: true,
          clientId:
              "AXi6aZh0nn5BZMhx37_ZOC69Ws9ZB6Zaps9Wjk-SOnIUCgsM1fywwbTuROKcf1LrMv1G9cwtcKh-ZtLf",
          secretKey:
              "EIwYNLrgFlzB7arvGLaBDmZMpWcRS0Ygq0sfr2ErYffwPdd6uOslY50laUxER9DdJ-cQ5nGhJPtmMMYV",
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
              "description": "The payment transaction description.",
              "item_list": {
                "items": cartDetails.entries.map((entry) {
                  return {
                    "name": entry.value['name'],
                    "quantity": entry.value['quantity'],
                    "price": entry.value['price'].toString(),
                    "currency": "USD"
                  };
                }).toList(),
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            print("onSuccess: $params");
            setState(() {
              cartDetails.clear();
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment successful!')),
            );
            if (user != null) {
              final conn = await DatabaseUtils.connect();
              double bonusPoints = totalPrice * 10;
              try {
                // Update user bonus account
                await conn.execute(
                  Sql.named(
                      'UPDATE public."User" SET "userBonusAccount" = COALESCE("userBonusAccount", 0) + @bonusPoints WHERE "userId" = @userId'),
                  parameters: {
                    'bonusPoints': bonusPoints,
                    'userId': user.uid,
                  },
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error updating bonus account: ${e.toString()}')),
                );
              } finally {
                await conn.close();
              }
            }
            // Insert order
            var orderIdResult = await conn.execute(
              Sql.named(
                  'INSERT INTO public."Order"("orderId", "userOrderId", "orderDate", "receiver", "receiverPhone", "paymentMethod") VALUES (gen_random_uuid(), @userId, CURRENT_TIMESTAMP, @receiver, @receiverPhone, @paymentMethod) RETURNING "orderId"'),
              parameters: {
                'userId': userId,
                'receiver': receiver,
                'receiverPhone': receiverPhone,
                'paymentMethod': 'NOW',
              },
            );

            var orderId = orderIdResult.first[0].toString();

            // Insert order products and update product quantities
            for (var entry in cartDetails.entries) {
              String productId = entry.key;
              int quantity = entry.value['quantity'];

              // Insert into OrderProductQuantity
              await conn.execute(
                Sql.named(
                    'INSERT INTO public."OrderProductQuantity"("orderProductQuantityId", "orderProductId", "orderProductQuantityProductId", "productQuantity") VALUES (gen_random_uuid(), @orderId, @productId, @quantity)'),
                parameters: {
                  'orderId': orderId,
                  'productId': productId,
                  'quantity': quantity,
                },
              );

              // Update product quantity in ProductShop
              await conn.execute(
                Sql.named(
                    'UPDATE public."ProductShop" SET "productQuantity" = "productQuantity" - @quantity WHERE "productId" = @productId'),
                parameters: {
                  'quantity': quantity,
                  'productId': productId,
                },
              );
            }

            // Clear the cart after order is placed
            await CartManager.clearCart(isLocal: true);
            setState(() {
              cartDetails.clear();
            });
            // Generate and share PDF receipt
            await generateAndSharePdfReceipt();

          },
          onError: (error) {
            print("onError: $error");
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment error: $error')),
            );
          },
          onCancel: () {
            print('cancelled:');
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment cancelled')),
            );
          },
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }

  Future<void> generateAndSharePdfReceipt() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Receipt', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Text('Thank you for your purchase!'),
              pw.SizedBox(height: 16),
              pw.Text('Order Details:'),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Product', 'Quantity', 'Price'],
                  ...cartDetails.entries.map((entry) {
                    return [
                      entry.value['name'] as String,
                      entry.value['quantity'].toString(),
                      '\$${(entry.value['price'] * entry.value['quantity']).toStringAsFixed(2)}',
                    ];
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt.pdf');
    await file.writeAsBytes(await pdf.save());

    Share.shareFiles([file.path], text: 'Here is your receipt');
  }

  void proceedToConfigureOrder() {
    if(CartManager.getCartItems().isNotEmpty){
      startPaypalCheckout(totalPrice);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ConfigureOrderScreen(
        totalPrice: totalPrice,
        cartDetails: cartDetails,
      ),
    ));
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800],shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
            
                  BarcodeScanService.scanBarcode(context, ()=> setState(() {
                            loadCartDetails(); // Refresh cart details
                          }));
                },
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Add', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
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
                                  onPressed: () async {
                                    await CartManager.deleteItem(productId,
                                        isLocal:
                                            CartManager.getCartItems().isNotEmpty);
                                    setState(() {
                                      cartDetails.remove(productId);
                                      loadCartDetails();
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
                                      onPressed: () async {
                                        await CartManager.removeItem(productId,
                                            isLocal: CartManager.getCartItems()
                                                .isNotEmpty);
                                        setState(() {
                                          if (CartManager.getCartItems()
                                                      .isNotEmpty &&
                                                  CartManager.getCartItems()[
                                                          productId] ==
                                                      null ||
                                              FirebaseAuth.instance
                                                          .currentUser !=
                                                      null &&
                                                  cartDetails[productId]
                                                          ?['quantity'] ==
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
                                      onPressed: () async {
                                        await CartManager.addItem(productId,
                                            isLocal: CartManager.getCartItems()
                                                .isNotEmpty);
                                        setState(() {
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
          padding: const EdgeInsets.symmetric( vertical: 30.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800],shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            
            onPressed: () {
              proceedToConfigureOrder();
            },
            child: Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        ),
      ],
    );
  }
}
