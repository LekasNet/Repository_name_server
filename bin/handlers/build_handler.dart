import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../db_connection.dart';
import 'package:uuid/uuid.dart';
import '../utils/user_dbrequest.dart';

Future<Response> createNewBuild(Request request) async {
  final user = await getUserFromRequest(request);
  if (user == null) return Response.forbidden('Unauthorized');

  final hash = Uuid().v4(); // Генерируем хэш для сборки
  final shared = '${hash}_${Uuid().v4().substring(0, 4)}'; // Генерируем значение для shared
  final db = await connectToDb();

  final expiresAt = user['user_type'] == 'temporary'
      ? DateTime.now().add(Duration(days: 30)) // Для временных пользователей
      : null;  // Для зарегистрированных пользователей сборка хранится без ограничения

  await db.query(
    '''
    INSERT INTO builds (hash, shared, user_id, user_type, created_at, expires_at) 
    VALUES (@hash, @shared, @user_id, @user_type, CURRENT_TIMESTAMP, @expires_at)
    ''',
    substitutionValues: {
      'hash': hash,
      'shared': shared,
      'user_id': user['user_id'],
      'user_type': user['user_type'],
      'expires_at': expiresAt?.toIso8601String(),
    },
  );

  await db.close();

  return Response.ok(hash);
}



Future<Response> getBuildComponentsByHash(Request request) async {
  // Проверяем авторизацию пользователя
  final user = await getUserFromRequest(request);
  if (user == null) {
    return Response.forbidden('Unauthorized');
  }

  final hash = request.url.queryParameters['hash'];
  if (hash == null || hash.isEmpty) {
    return Response.badRequest(body: 'Missing or invalid hash parameter');
  }

  final db = await connectToDb();

  try {
    // Проверяем существование сборки
    final buildCheck = await db.query(
      '''
      SELECT id FROM builds
      WHERE hash = @hash AND user_id = @user_id AND user_type = @user_type
    ''',
      substitutionValues: {
        'hash': hash,
        'user_id': user['user_id'],
        'user_type': user['user_type'],
      },
    );

    if (buildCheck.isEmpty) {
      return Response.notFound('Build not found or unauthorized access');
    }

    // Запрашиваем компоненты сборки
    final result = await db.query(
      '''
      SELECT 
        components.id, 
        components.name, 
        components.price, 
        categories.name AS category, 
        components.image_url
      FROM 
        build_components
      JOIN 
        components ON build_components.component_id = components.id
      JOIN 
        categories ON components.category_id = categories.id
      WHERE 
        build_components.build_id = @build_id;
    ''',
      substitutionValues: {
        'build_id': buildCheck[0][0],
      },
    );

    // Возвращаем пустой массив, если компонентов нет
    if (result.isEmpty) {
      return Response.ok(
        jsonEncode([]),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Формируем список компонентов
    final List<Map<String, dynamic>> components = result.map((row) {
      return {
        'id': row[0],
        'name': row[1],
        'price': row[2],
        'category': row[3],
        'image_url': row[4],
      };
    }).toList();

    return Response.ok(
      jsonEncode(components),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
        body: 'Error retrieving components: $e');
  } finally {
    await db.close();
  }
}

Future<Response> getSharedLink(Request request) async {
  final hash = request.url.queryParameters['hash'];

  if (hash == null || hash.isEmpty) {
    return Response.badRequest(body: 'Missing or invalid hash parameter');
  }

  final db = await connectToDb();

  try {
    // Получаем запись сборки по hash
    final result = await db.query(
      '''
      SELECT shared 
      FROM builds 
      WHERE hash = @hash
      ''',
      substitutionValues: {'hash': hash},
    );

    if (result.isEmpty) {
      return Response.notFound('Build not found for the provided hash');
    }

    // Формируем полный URL
    final shared = result.first[0];
    final baseUrl = 'https://adssh.ru'; // Базовый URL приложения
    final fullLink = '$baseUrl/open_build?shared=$shared';

    return Response.ok(
      jsonEncode({'shared': fullLink}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Error retrieving shared link: $e');
  } finally {
    await db.close();
  }
}



Future<Response> getSharedBuild(Request request) async {
  final shared = request.url.queryParameters['shared'];

  if (shared == null || shared.isEmpty) {
    return Response.badRequest(body: 'Missing or invalid shared parameter');
  }

  final db = await connectToDb();

  try {
    // Проверяем, существует ли сборка с таким shared
    final result = await db.query(
      '''
      SELECT 
        builds.hash, 
        components.id AS component_id, 
        components.name, 
        components.price, 
        categories.name AS category, 
        components.image_url
      FROM builds
      JOIN build_components ON builds.id = build_components.build_id
      JOIN components ON build_components.component_id = components.id
      JOIN categories ON components.category_id = categories.id
      WHERE builds.shared = @shared
      ''',
      substitutionValues: {'shared': shared},
    );

    if (result.isEmpty) {
      return Response.notFound('No build found for this shared link');
    }

    // Формируем данные сборки
    final buildHash = result.first[0]; // Предполагается, что hash находится в первой колонке
    final components = result.map((row) {
      return {
        'id': row[1],          // component_id на втором месте
        'name': row[2],        // name на третьем месте
        'price': row[3],       // price на четвёртом месте
        'category': row[4],    // category на пятом месте
        'image_url': row[5],   // image_url на шестом месте
      };
    }).toList();


    return Response.ok(
      jsonEncode({
        'hash': buildHash,
        'components': components,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Error fetching shared build: $e');
  } finally {
    await db.close();
  }
}
