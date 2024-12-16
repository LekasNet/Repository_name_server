import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../db_connection.dart';

Future<Response> addTemporaryUser(Request request) async {
  final token = Uuid().v4();
  final expiresAt = DateTime.now().add(Duration(days: 30)); // токен будет действовать 30 дней

  final db = await connectToDb();
  await db.query('INSERT INTO temporary_users (token, expires_at) VALUES (@token, @expires_at)',
      substitutionValues: {
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
      });

  await db.close();

  return Response.ok('TU_$token');
}
