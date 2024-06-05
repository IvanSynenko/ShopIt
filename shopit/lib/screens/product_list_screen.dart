// screens/product_list_screen.dart
import 'package:flutter/material.dart';
import '../utils/db_utils.dart';
import '../widgets/product_item.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String subcategoryId;
  final List<Map<String, dynamic>>? searchResults;

  ProductListScreen({required this.subcategoryId, this.searchResults});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> products = [];
  TextEditingController searchController = TextEditingController();
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    if (widget.searchResults != null) {
      products = widget.searchResults!;
    } else {
      loadProducts();
    }
  }

  void loadProducts() async {
    products = await DatabaseUtils.fetchProducts(widget.subcategoryId);
    setState(() {});
  }

  void searchProducts(String query) async {
    if (query.isNotEmpty) {
      var results = await DatabaseUtils.searchProducts(query);
      setState(() {
        products = results;
      });
    }
  }

  void sortProducts(bool ascending) {
    setState(() {
      products = DatabaseUtils.sortProductsByPrice(products, ascending);
      isAscending = ascending;
    });
  }

  void filterProducts(double minPrice, double maxPrice) {
    setState(() {
      products =
          DatabaseUtils.filterProductsByPrice(products, minPrice, maxPrice);
    });
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for goods',
                          border: InputBorder.none,
                        ),
                        onSubmitted: searchProducts,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => searchProducts(searchController.text),
                    ),
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
                      sortProducts(!isAscending);
                    },
                    child: Text(
                        isAscending ? 'Sort by Price ↑' : 'Sort by Price ↓'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showFilterDialog();
                    },
                    child: Text('Filter by Price'),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: products.map((product) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: product['productId'],
                          ),
                        ),
                      );
                    },
                    child: ProductItem(
                      title: product['productName'],
                      image: 'assets/placeholder.png',
                      price: '\$${product['price']}',
                      productId: product['productId'],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    double minPrice = 0;
    double maxPrice = 1000;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter by Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Min Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  minPrice = double.tryParse(value) ?? 0;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Max Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  maxPrice = double.tryParse(value) ?? 1000;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                filterProducts(minPrice, maxPrice);
                Navigator.of(context).pop();
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
