import 'package:postgres/postgres.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_utils.dart';

class CartManager {
  static final Map<String, int> _localCartItems = {};

  static Future<void> addItem(String productId, {bool isLocal = true}) async {
    if (isLocal) {
      if (await _hasDbCart()) {
        throw('Empty your online cart before adding items locally.');
      }
      if (_localCartItems.containsKey(productId)) {
        _localCartItems[productId] = _localCartItems[productId]! + 1;
      } else {
        _localCartItems[productId] = 1;
      }
      print(
          'Added to local cart: $productId, quantity: ${_localCartItems[productId]}');
    } else {
      if (_localCartItems.isNotEmpty) {
        throw('Empty your local cart before adding items online.');
      }
      await _addToDbCart(productId);
    }
  }

  static Future<void> removeItem(String productId,
      {bool isLocal = true}) async {
    if (isLocal) {
      if (_localCartItems.containsKey(productId)) {
        if (_localCartItems[productId]! > 1) {
          _localCartItems[productId] = _localCartItems[productId]! - 1;
        } else {
          _localCartItems.remove(productId);
        }
      }
    } else {
      await _removeFromDbCart(productId);
    }
  }

  static Future<void> deleteItem(String productId,
      {bool isLocal = true}) async {
    if (isLocal) {
      _localCartItems.remove(productId);
    } else {
      await _deleteFromDbCart(productId);
    }
  }

  static Map<String, int> getCartItems() {
    return _localCartItems;
  }

  static Future<void> clearCart({bool isLocal = true}) async {
    if (isLocal) {
      _localCartItems.clear();
    } else {
      await _clearDbCart();
    }
  }

  static double getTotalPrice(Map<String, double> productPrices) {
    double total = 0;
    _localCartItems.forEach((id, quantity) {
      total += (productPrices[id] ?? 0) * quantity;
    });
    return total;
  }

  static Future<bool> _hasDbCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final conn = await DatabaseUtils.connect();
    var result = await conn.execute(
      Sql.named(
          'SELECT COUNT(*) FROM public."UsersProductQuantity" WHERE "userId" = @userId'),
      parameters: {
        'userId': user.uid,
      },
    );
    await conn.close();
    return result.isNotEmpty && (result.first[0] as int) > 0;
  }

  static Future<void> _addToDbCart(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conn = await DatabaseUtils.connect();
    var result = await conn.execute(
      Sql.named(
          'SELECT "productQuantity" FROM public."UsersProductQuantity" WHERE "productId" = @productId AND "userId" = @userId'),
      parameters: {
        'productId': productId,
        'userId': user.uid,
      },
    );

    if (result.isNotEmpty) {
      await conn.execute(
        Sql.named(
            'UPDATE public."UsersProductQuantity" SET "productQuantity" = "productQuantity" + 1 WHERE "productId" = @productId AND "userId" = @userId'),
        parameters: {
          'productId': productId,
          'userId': user.uid,
        },
      );
    } else {
      await conn.execute(
        Sql.named(
            'INSERT INTO public."UsersProductQuantity"("usersProductQuantityId", "productQuantity", "productId", "userId") VALUES (gen_random_uuid(), 1, @productId, @userId)'),
        parameters: {
          'productId': productId,
          'userId': user.uid,
        },
      );
    }
    await conn.close();
  }

  static Future<void> _removeFromDbCart(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conn = await DatabaseUtils.connect();
    var result = await conn.execute(
      Sql.named(
          'SELECT "productQuantity" FROM public."UsersProductQuantity" WHERE "productId" = @productId AND "userId" = @userId'),
      parameters: {
        'productId': productId,
        'userId': user.uid,
      },
    );

    if (result.isNotEmpty && (result.first[0] as int) > 1) {
      await conn.execute(
        Sql.named(
            'UPDATE public."UsersProductQuantity" SET "productQuantity" = "productQuantity" - 1 WHERE "productId" = @productId AND "userId" = @userId'),
        parameters: {
          'productId': productId,
          'userId': user.uid,
        },
      );
    } else {
      await conn.execute(
        Sql.named(
            'DELETE FROM public."UsersProductQuantity" WHERE "productId" = @productId AND "userId" = @userId'),
        parameters: {
          'productId': productId,
          'userId': user.uid,
        },
      );
    }
    await conn.close();
  }

  static Future<void> _deleteFromDbCart(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conn = await DatabaseUtils.connect();
    await conn.execute(
      Sql.named(
          'DELETE FROM public."UsersProductQuantity" WHERE "productId" = @productId AND "userId" = @userId'),
      parameters: {
        'productId': productId,
        'userId': user.uid,
      },
    );
    await conn.close();
  }

  static Future<void> _clearDbCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conn = await DatabaseUtils.connect();
    await conn.execute(
      Sql.named(
          'DELETE FROM public."UsersProductQuantity" WHERE "userId" = @userId'),
      parameters: {
        'userId': user.uid,
      },
    );
    await conn.close();
  }
}
