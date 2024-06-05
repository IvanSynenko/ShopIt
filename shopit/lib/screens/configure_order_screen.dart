import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import '../utils/cart_manager.dart';
import '../utils/db_utils.dart';
import 'delivery_method_screen.dart';
import 'receiver_screen.dart';
import 'payment_method_screen.dart';
class ConfigureOrderScreen extends StatefulWidget {
  final double totalPrice;
  final Map<String, Map<String, dynamic>> cartDetails;

  ConfigureOrderScreen({required this.totalPrice, required this.cartDetails});

  @override
  _ConfigureOrderScreenState createState() => _ConfigureOrderScreenState();
}

class _ConfigureOrderScreenState extends State<ConfigureOrderScreen> {
  String deliveryMethod = "Pick up at a store";
  String paymentMethod = "Upon receipt";
  String receiverName = "";
  String receiverPhone = "";
  String deliveryService = "";
  String deliveryAddress = "";

  double get deliveryPrice {
    switch (deliveryMethod) {
      case "Pick up at a delivery point":
        return 5.0;
      case "Home delivery":
        return 10.0;
      default:
        return 0.0;
    }
  }

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
          receiverName = result.first[0] as String? ?? "";
          receiverPhone = result.first[1] as String? ?? "";
        });
      }
      await conn.close();
    }
  }
  Future<void> clearCartAndRefresh() async {
    await CartManager.clearCart(isLocal: false); // Clear the cart
    setState(() {
      widget.cartDetails.clear();
    });
  }
  String getDeliveryMethodEnum(String deliveryMethod) {
    switch (deliveryMethod) {
      case 'Pick up at a store':
        return 'STORE';
      case 'Pick up at a delivery point':
        return 'DELIVERY_POINT';
      case 'Home delivery':
        return 'HOME_DELIVERY';
      default:
        throw Exception('Unknown delivery method: $deliveryMethod');
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in the delivery address.')),
      );
      return;
    }
    final conn = await DatabaseUtils.connect();
    try {
        // Insert into Order table
        var orderResult = await conn.execute(
          Sql.named(
              'INSERT INTO public."Order"("orderId", "userOrderId", "orderDate", "receiver", "receiverPhone", "paymentMethod") VALUES (gen_random_uuid(), @userId, NOW(), @receiver, @phone, @paymentMethod) RETURNING "orderId"'),
          parameters: {
            'userId': user.uid,
            'receiver': receiverName,
            'phone': receiverPhone,
            'paymentMethod': paymentMethod == "Now" ? 'NOW' : 'UPON_RECEIPT',
          },
        );

        String orderId = orderResult.first[0].toString();

        // Insert into OrderProductQuantity table
        for (var entry in widget.cartDetails.entries) {
          await conn.execute(
            Sql.named(
                'INSERT INTO public."OrderProductQuantity"("orderProductQuantityId", "orderProductId", "orderProductQuantityProductId", "productQuantity") VALUES (gen_random_uuid(), @orderId, @productId, @quantity)'),
            parameters: {
              'orderId': orderId,
              'productId': entry.key,
              'quantity': entry.value['quantity'],
            },
          );
        }

        // Insert into Delivery table
        await conn.execute(
          Sql.named(
              'INSERT INTO public."Delivery"("deliveryId", "deliveryMethod", "deliveryAddress", "deliveryPrice", "deliveryOrderId") VALUES (gen_random_uuid(), @method, @address, @price, @orderId)'),
          parameters: {
            'method': getDeliveryMethodEnum(deliveryMethod),
            'address': deliveryAddress,
            'price': deliveryPrice,
            'orderId': orderId,
          },
        );


      if (paymentMethod == "Now") {
        startPaypalCheckout(widget.totalPrice + deliveryPrice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed successfully!')),
        );
        
        Navigator.pop(context);
        clearCartAndRefresh();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }

  void startPaypalCheckout(double totalPrice) {
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
              "items": widget.cartDetails.entries.map((entry) {
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
          clearCartAndRefresh();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment successful!')),
          );
          // Add database update for orders, product quantity, pdf receipt formation
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
  }

  @override
  Widget build(BuildContext context) {
    double totalOrderPrice = widget.totalPrice + deliveryPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configure Order'),
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
              Text('Order',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Divider(),
              buildOrderDetails(),
              buildOptionBox('Delivery', deliveryMethod, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryMethodScreen(
                      currentDeliveryMethod: deliveryMethod,
                      onDeliveryMethodChanged: (newMethod) {
                        setState(() {
                          deliveryMethod = newMethod;
                        });
                      },
                      onDeliveryDetailsChanged: (details) {
                        setState(() {
                          deliveryService = details['service'] ?? "";
                          deliveryAddress = details['address'] ?? "";
                        });
                      },
                    ),
                  ),
                );
              }),
              buildOptionBox('Payment method', paymentMethod, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentMethodScreen(
                      currentPaymentMethod: paymentMethod,
                      onPaymentMethodChanged: (newMethod) {
                        setState(() {
                          paymentMethod = newMethod;
                        });
                      },
                    ),
                  ),
                );
              }),
              buildOptionBox('Receiver', '$receiverName\n$receiverPhone', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiverScreen(
                      currentName: receiverName,
                      currentPhone: receiverPhone,
                      onReceiverChanged: (name, phone) {
                        setState(() {
                          receiverName = name;
                          receiverPhone = phone;
                        });
                      },
                    ),
                  ),
                );
              }),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${widget.cartDetails.length} product(s) for the total price of'),
                    Text('\$${widget.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery price'),
                    Text('\$${deliveryPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total'),
                    Text('\$${totalOrderPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: () {
                    _placeOrder();
                  },
                  child: Text('Confirm order',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOrderDetails() {
    return Column(
      children: widget.cartDetails.entries.map((entry) {
        return ListTile(
          title: Text(entry.value['name']),
          subtitle:
              Text('${entry.value['quantity']} x \$${entry.value['price']}'),
        );
      }).toList(),
    );
  }

  Widget buildOptionBox(
      String title, String currentValue, VoidCallback onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(currentValue),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onChange,
                child: Text('Change', style: TextStyle(color: Colors.purple)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
