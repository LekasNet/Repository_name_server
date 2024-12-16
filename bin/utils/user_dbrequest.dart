import 'dart:async';
import 'package:shelf/shelf.dart';
import '../db_connection.dart';

Future<Map<String, dynamic>?> getUserFromRequest(Request request) async {
  // Извлекаем токен из заголовка Authorization
  final authHeader = request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null; // Нет токена в заголовке
  }

  final token = authHeader.substring(7); // Получаем сам токен (после "Bearer ")

  final db = await connectToDb();

  // Сначала ищем зарегистрированного пользователя по email/паролю (если это зарегистрированный пользователь)
  var result = await db.query(
    'SELECT * FROM users WHERE email = @token OR password_hash = @token',
    substitutionValues: {'token': token},
  );

  if (result.isNotEmpty) {
    // Если нашли пользователя, возвращаем его данные
    await db.close();
    return {
      'user_id': result.first[0], // id пользователя
      'user_type': 'registered',  // Тип пользователя
      'email': result.first[1],   // email пользователя
    };
  }

  // Если не нашли, ищем в таблице временных пользователей
  result = await db.query(
    'SELECT * FROM temporary_users WHERE token = @token',
    substitutionValues: {'token': token},
  );

  if (result.isNotEmpty) {
    // Если нашли временного пользователя, возвращаем его данные
    await db.close();
    return {
      'user_id': result.first[0],  // id временного пользователя
      'user_type': 'temporary',    // Тип пользователя
      'token': result.first[1],    // Токен
    };
  }

  await db.close();
  return null; // Не найден пользователь
}
