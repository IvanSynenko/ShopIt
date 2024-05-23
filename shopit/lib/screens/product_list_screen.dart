// screens/product_list_screen.dart
import 'package:flutter/material.dart';
import '../utils/db_utils.dart';
import '../widgets/product_item.dart';

class ProductListScreen extends StatefulWidget {
  final String subcategoryId;

  ProductListScreen({required this.subcategoryId});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void loadProducts() async {
    products = await DatabaseUtils.fetchProducts(widget.subcategoryId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add sort by price functionality
                    },
                    child: Text('Sort by Price'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add filter by price functionality
                    },
                    child: Text('Filter by Price'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: products.map((product) {
                  return ProductItem(
                    title: product['productName'],
                    image: 'assets/placeholder.png', 
                    price: '\$${product['price']}',
                                        onTap: () {
                      // Add to cart functionality
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

