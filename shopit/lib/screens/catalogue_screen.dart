// screens/catalogue_screen.dart
import 'package:flutter/material.dart';
import '../utils/db_utils.dart';
import '../widgets/category_item.dart';
import 'subcategory_screen.dart';
import 'product_list_screen.dart';

class CatalogueScreen extends StatefulWidget {
  @override
  _CatalogueScreenState createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  List<Map<String, dynamic>> categories = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    categories = await DatabaseUtils.fetchCategories();
    setState(() {});
  }

  void searchProducts(String query) async {
    if (query.isNotEmpty) {
      var results = await DatabaseUtils.searchProducts(query);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            subcategoryId: '',
            searchResults: results,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Catalogue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: CategoryItem(
                  title: category['category'],
                  image:
                      'assets/placeholder.png', // Replace with your category image
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryScreen(
                          categoryId: category['categoryId'],
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
