// screens/subcategory_screen.dart
import 'package:flutter/material.dart';
import '../utils/db_utils.dart';
import 'product_list_screen.dart';

class SubCategoryScreen extends StatefulWidget {
  final String categoryId;

  SubCategoryScreen({required this.categoryId});

  @override
  _SubCategoryScreenState createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<Map<String, dynamic>> subcategories = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSubcategories();
  }

  void loadSubcategories() async {
    subcategories = await DatabaseUtils.fetchSubcategories(widget.categoryId);
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
      appBar: AppBar(
        title: Text('Subcategories'),
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
            ...subcategories.map((subcategory) {
              return ListTile(
                title: Text(subcategory['subcategoryName']),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/productList',
                    arguments: subcategory['subcategoryId'],
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
