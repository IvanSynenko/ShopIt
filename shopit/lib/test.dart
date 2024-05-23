import 'package:postgres/postgres.dart';
void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'shopit-db.cjgagme48oci.eu-north-1.rds.amazonaws.com',
      database: 'clever_shop',
      username: 'master',
      password: 'password',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );
  print('has connection!');


  await conn.close();
}
