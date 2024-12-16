import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db_connection.dart';

Future<Response> addAuthorizedUser(Request request) async {
  final db = await connectToDb();

  try {
    // Чтение тела запроса
    final body = await request.readAsString();
    final Map<String, dynamic> data = jsonDecode(body);

    final String? userHash = data['hash'];
    final String? email = data['email'];

    if (userHash == null || userHash.isEmpty) {
      return Response.badRequest(body: 'Missing or invalid hash');
    }

    if (email == null || email.isEmpty) {
      return Response.badRequest(body: 'Missing or invalid email');
    }

    // Проверяем, существует ли уже пользователь с таким хэшем
    final existingUser = await db.query(
      '''
      SELECT id FROM users WHERE password_hash = @hash
      ''',
      substitutionValues: {'hash': userHash},
    );

    if (existingUser.isNotEmpty) {
      return Response.ok('User already exists');
    }

    // Добавляем нового пользователя
    await db.query(
      '''
      INSERT INTO users (password_hash, email, created_at)
      VALUES (@hash, @email, CURRENT_TIMESTAMP)
      ''',
      substitutionValues: {
        'hash': userHash,
        'email': email,
      },
    );

    return Response.ok('User added successfully');
  } catch (e) {
    return Response.internalServerError(body: 'Error adding user: $e');
  } finally {
    await db.close();
  }
}
