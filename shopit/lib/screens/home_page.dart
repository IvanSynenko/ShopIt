import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'catalogue_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  HomePage({this.initialIndex = 0});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CatalogueScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShopIt'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        color: Colors.pink[100], 
        height: 60, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) => buildTabItem(index)),
        ),
      ),
    );
  }

  Widget buildTabItem(int index) {
    IconData icon;
    switch (index) {
      case 0:
        icon = Icons.home;
        break;
      case 1:
        icon = Icons.list;
        break;
      case 2:
        icon = Icons.shopping_cart;
        break;
      case 3:
        icon = Icons.person;
        break;
      default:
        icon = Icons.home; // fallback for error
    }
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250), 
          curve: Curves.easeInOut, 
          color:
              index == _selectedIndex ? Colors.pink[300] : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(icon,
              color: index == _selectedIndex
                  ? Colors.black
                  : Colors.black.withOpacity(0.6)),
        ),
      ),
    );
  }
}
