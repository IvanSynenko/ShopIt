import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postgres/postgres.dart';
import 'cart_manager.dart';
import 'geolocation.dart';

class BarcodeScanService {
  static Future<void> scanBarcode(BuildContext context, Function onProductAdded) async {
    var result = await BarcodeScanner.scan(
      options: ScanOptions(
        useCamera: -1, // default camera
        autoEnableFlash: false,
        android: AndroidOptions(
          aspectTolerance: 0.00,
          useAutoFocus: true,
        ),
      ),
    );

    if (result.type == ResultType.Barcode) {
      handleProductScan(result.rawContent, context, onProductAdded);
    } else if (result.type == ResultType.Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning Error: ${result.rawContent}')),
      );
    }
  }

  static void handleProductScan(String barcode, BuildContext context, Function onProductAdded) async {
    final conn = await Connection.open(
      Endpoint(
        host: 'shopit-db.cjgagme48oci.eu-north-1.rds.amazonaws.com',
        database: 'clever_shop',
        username: 'master',
        password: 'password',
      ),
      settings: ConnectionSettings(sslMode: SslMode.require),
    );

    try {
      // Get the user's current location
      Position position = await GeolocationService().getCurrentLocation();

      // Find the nearest store
      var storeResult = await conn.execute(
        Sql.named(
            'SELECT "shopId", ST_Distance("location", ST_SetSRID(ST_MakePoint(@lng, @lat), 4326)) AS distance '
            'FROM public."Shop" '
            'ORDER BY distance LIMIT 1'),
        parameters: {
          'lng': position.longitude,
          'lat': position.latitude,
        },
      );

      if (storeResult.isNotEmpty) {
        String shopId = storeResult.first[0].toString();

        // Find the product in the nearest store
        var productResult = await conn.execute(
          Sql.named('SELECT * FROM public."ProductShop" '
              'WHERE "productID" = @barcode AND "shopID" = @shopId'),
          parameters: {
            'barcode': barcode,
            'shopId': shopId,
          },
        );

        if (productResult.isNotEmpty) {
          String productId = productResult.first[2].toString();
          CartManager.addItem(productId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product added to cart!')),
          );
           onProductAdded();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product not found in this store')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No nearby store found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      await conn.close();
    }
  }
}
