// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:postgres/postgres.dart';
import '../utils/cart_manager.dart';
import '../utils/db_utils.dart';
import 'subcategory_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> mostBoughtCategories = [];

  @override
  void initState() {
    super.initState();
    loadMostBoughtCategories();
  }

  void loadMostBoughtCategories() async {
    List<Map<String, dynamic>> categories =
        await DatabaseUtils.fetchCategories();
    if (categories.length >= 2) {
      setState(() {
        mostBoughtCategories = categories.take(2).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/shopit_logo.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Search for goods'),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: GestureDetector(
              onTap: () => scanBarcode(context),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.barcode_reader, color: Colors.purple),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Scan items quick and easy'),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.purple),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Order items online'),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
          Divider(color: Colors.black),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text('Most often bought categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: mostBoughtCategories.map((category) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryScreen(
                            categoryId: category['categoryId']),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['category'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Row(
            children: mostBoughtCategories.map((category) {
              return Expanded(
                child: Column(
                  children: [
                    
                    Image.asset(
                      'assets/placeholder.png', 
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: MediaQuery.of(context).size.width * 0.45,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> scanBarcode(BuildContext context) async {
    var result = await BarcodeScanner.scan(
      options: ScanOptions(
        useCamera: -1, // default camera
        autoEnableFlash: false,
        android: AndroidOptions(
          aspectTolerance: 0.00,
          useAutoFocus: true,
        ),
      ),
    );

    if (result.type == ResultType.Barcode) {
      handleProductScan(result.rawContent, context);
    } else if (result.type == ResultType.Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning Error: ${result.rawContent}')),
      );
    }
  }

  void handleProductScan(String barcode, BuildContext context) async {
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
      var result = await conn.execute(
          Sql.named(
              'SELECT * FROM public."Product" WHERE "productId" = @barcode'),
          parameters: {'barcode': barcode});

      if (result.isNotEmpty) {
        String productId = result.first[0].toString();
        CartManager.addItem(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added to cart!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }
}
