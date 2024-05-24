class CartManager {
  static final Map<String, int> _cartItems = {};

  static void addItem(String productId) {
    if (_cartItems.containsKey(productId)) {
      _cartItems[productId] = _cartItems[productId]! + 1;
    } else {
      _cartItems[productId] = 1;
    }
    print('Added to cart: $productId, quantity: ${_cartItems[productId]}');
  }

  static void removeItem(String productId) {
    if (_cartItems.containsKey(productId)) {
      if (_cartItems[productId]! > 1) {
        _cartItems[productId] = _cartItems[productId]! - 1;
      } else {
        _cartItems.remove(productId);
      }
    }
  }

  static Map<String, int> getCartItems() {
    return _cartItems;
  }

  static void clearCart() {
    _cartItems.clear();
  }

  static double getTotalPrice(Map<String, double> productPrices) {
    double total = 0;
    _cartItems.forEach((id, quantity) {
      total += (productPrices[id] ?? 0) * quantity;
    });
    return total;
  }
}
