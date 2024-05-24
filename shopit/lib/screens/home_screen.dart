import 'package:flutter/material.dart';
import '../utils/db_utils.dart';
import 'subcategory_screen.dart';
import '../utils/barcode_scan.dart';
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
              onTap: () => BarcodeScanService.scanBarcode(context,(){setState(() {
                  // Reload data or update UI if necessary
                });}),
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
}
