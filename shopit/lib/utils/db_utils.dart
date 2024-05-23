// utils/db_utils.dart
import 'package:postgres/postgres.dart';

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
    var results = await conn.execute(Sql.named(
          'SELECT "subcategoryId", "subcategoryName" FROM public."Subcategory" WHERE "categorySubcategoryId" = @categoryId')
      ,
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
    var results = await conn.execute(Sql.named(
          'SELECT "productId", "productName", "productDescription", "productBrand", "price" FROM public."Product" WHERE "subcategoryId" = @subcategoryId')
      ,
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
}
