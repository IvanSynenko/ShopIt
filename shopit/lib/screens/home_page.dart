import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'catalogue_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'subcategory_screen.dart';
import 'product_list_screen.dart';
import 'product_detail_screen.dart';
import 'purchase_history_screen.dart';
import 'manage_account_screen.dart';
import 'bonus_program_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'change_language_screen.dart';
import 'delete_account_screen.dart';
import 'notifications_page.dart';
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

  Widget getCurrentScreen() {
    if (_selectedIndex == 1 && Navigator.canPop(context)) {
      return Navigator(
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (context) => CatalogueScreen();
              break;
            case '/subcategory':
              builder = (context) => SubCategoryScreen(
                    categoryId: settings.arguments as String,
                  );
              break;
            case '/productList':
              builder = (context) => ProductListScreen(
                    subcategoryId: settings.arguments as String,
                  );
              break;
            case '/productDetail':
              builder = (context) => ProductDetailScreen(
                    productId: settings.arguments as String,
                  );
              break;
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return MaterialPageRoute(builder: builder);
        },
      );
    } else if (_selectedIndex == 3 && Navigator.canPop(context)) {
      return Navigator(
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (context) => ProfileScreen();
              break;
            case '/purchaseHistory':
              builder = (context) => PurchaseHistoryScreen();
              break;
            case '/manageAccount':
              builder = (context) => ManageAccountScreen();
              break;
            case '/bonusProgram':
              builder = (context) => BonusProgramScreen();
              break;
            case '/changeEmail':
              builder = (context) => ChangeEmailScreen();
              break;
            case '/changePassword':
              builder = (context) => ChangePasswordScreen();
              break;
            case '/changeLanguage':
              builder = (context) => ChangeLanguageScreen();
              break;
            case '/deleteAccount':
              builder = (context) => DeleteAccountScreen();
              break;
             case '/notifications':
              builder = (context) => NotificationsPage();
              break; 
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return MaterialPageRoute(builder: builder);
        },
      );
    } else {
      return _widgetOptions.elementAt(_selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShopIt'),
      ),
      body: getCurrentScreen(),
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
