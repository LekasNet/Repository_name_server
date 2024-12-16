import 'package:postgres/postgres.dart';

// Создание нового подключения
Future<PostgreSQLConnection> connectToDb() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'configurator-database',
    username: 'postgres',
    password: '4600919',
  );
  await connection.open();
  return connection;
}