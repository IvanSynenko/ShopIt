import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:geolocator/geolocator.dart';
class DatabaseUtils {
  static Future<Connection> connect() async {
    final conn = await Connection.open(
      Endpoint(
        host: 'shopit-db.cjgagme48oci.eu-north-1.rds.amazonaws.com',
        database: 'clever_shop',
        username: 'master',
        password: 'password',
      ),
      settings: ConnectionSettings(sslMode: SslMode.require),
    );

    return conn;
  }
  static Future<List<Map<String, dynamic>>> fetchStoresWithinRadius(
      double latitude, double longitude, double radius) async {
    final conn = await connect();
    var results = await conn.execute(
      Sql.named(
          'SELECT "shopId", "location", "shopAddress" FROM public."Shop" WHERE ST_DWithin("location", ST_SetSRID(ST_MakePoint(@longitude, @latitude), 4326)::geography, @radius)'),
      parameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius * 1000, // Convert km to meters
      },
    );
    await conn.close();

    return results.map((row) {
      return {
        'shopId': row[0],
        'location': row[1],
        'shopAddress': row[2],
      };
    }).toList();
  }
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final conn = await connect();
    var results = await conn
        .execute('SELECT "categoryId", category::text FROM public."Category"');
    await conn.close();
    return results
        .map((row) => {
              'categoryId': row[0],
              'category': row[1],
            })
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchSubcategories(
      String categoryId) async {
    final conn = await connect();
    var results = await conn.execute(
      Sql.named(
          'SELECT "subcategoryId", "subcategoryName" FROM public."Subcategory" WHERE "categorySubcategoryId" = @categoryId'),
      parameters: {'categoryId': categoryId},
    );
    await conn.close();
    return results
        .map((row) => {
              'subcategoryId': row[0],
              'subcategoryName': row[1],
            })
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchProducts(
      String subcategoryId) async {
    final conn = await connect();
    var results = await conn.execute(
      Sql.named(
          'SELECT "productId", "productName", "productDescription", "productBrand", "price" FROM public."Product" WHERE "subcategoryId" = @subcategoryId'),
      parameters: {'subcategoryId': subcategoryId},
    );
    await conn.close();
    return results
        .map((row) => {
              'productId': row[0],
              'productName': row[1],
              'productDescription': row[2],
              'productBrand': row[3],
              'price': row[4],
            })
        .toList();
  }

  static String hashPassword(String password) {
    var bytes = utf8.encode(password); 
    var digest = sha256.convert(bytes); 
    return digest.toString(); 
  }

  static Future<void> registerNewUser({
    required String userId,
    required String email,
    required String name,
    required String surname,
    required String phoneNumber,
    required String password,
  }) async {
    final conn = await connect();
    try {
      String hashedPassword = hashPassword(password); 

      await conn.execute(
        Sql.named(
            'INSERT INTO public."User" ("userId", "userEmail", "userName", "userPassword", "userPhoneNumber") VALUES (@userId, @userEmail, @userName, @userPassword, @userPhoneNumber)'),
        parameters: {
          'userId': userId,
          'userEmail': email,
          'userName': '$name $surname',
          'userPassword': hashedPassword, 
          'userPhoneNumber': phoneNumber,
        },
      );
    } finally {
      await conn.close();
    }
  }
}
