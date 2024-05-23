// utils/cart_manager.dart
class CartManager {
  static final List<String> _cartItems = [];

  static void addItem(String productId) {
    _cartItems.add(productId);
    print('Added to cart: $productId');
  }

  static List<String> getCartItems() {
    return _cartItems;
  }
}
