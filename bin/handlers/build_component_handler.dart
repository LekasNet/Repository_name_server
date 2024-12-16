import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import '../db_connection.dart';
import '../utils/user_dbrequest.dart';

Future<Response> addComponentToBuild(Request request) async {
  final user = await getUserFromRequest(request);
  if (user == null) {
    return Response.forbidden('Unauthorized');
  }

  final responce = await request.readAsString();
  print(responce);
  final Map<String, dynamic> queryParams = jsonDecode(responce);
  final buildHash = queryParams['build_hash'];
  final componentId = queryParams['component_id'] ?? '';

  if (buildHash == null || componentId == null) {
    print(buildHash);
    return Response.badRequest(body: 'Missing required parameters');
  }

  final db = await connectToDb();
  // Проверяем, существует ли сборка и принадлежит ли она текущему пользователю
  final buildResult = await db.query(
    'SELECT * FROM builds WHERE hash = @hash AND user_id = @user_id',
    substitutionValues: {
      'hash': buildHash,
      'user_id': user['user_id'],
    },
  );

  if (buildResult.isEmpty) {
    return Response.notFound('Build not found or unauthorized');
  }

  // Проверяем, совместим ли компонент с другими
  final incompatibleComponent = await checkComponentCompatibility(db, buildHash, componentId);
  if (incompatibleComponent != null) {
    return Response(418, body: 'Incompatible components: ${incompatibleComponent['name']} and ${incompatibleComponent['incompatible_with']}');
  }
  // Добавляем компонент в сборку
  await db.query(
    'INSERT INTO build_components (build_id, component_id) VALUES ((SELECT id FROM builds WHERE hash = @hash), @component_id)',
    substitutionValues: {
      'hash': buildHash,
      'component_id': componentId,
    },
  );

  await db.close();

  return Response.ok('Component added successfully');
}

Future<Map<String, dynamic>?> checkComponentCompatibility(PostgreSQLConnection db, String buildHash, int componentId) async {
  // Логика проверки совместимости
  // Возвращаем компонент с несовместимостью, если найдено
  return null; // Просто пример, нужно реализовать логику
}

// handlers/build_component_handler.dart

Future<Response> removeComponentFromBuild(Request request) async {
  final user = await getUserFromRequest(request);
  if (user == null) {
    return Response.forbidden('Unauthorized');
  }

  final responce = await request.readAsString();
  print(responce);
  final Map<String, dynamic> queryParams = jsonDecode(responce);
  final buildHash = queryParams['build_hash'];
  final componentId = queryParams['component_id'] ?? '';

  if (buildHash == null || componentId == null) {
    return Response.badRequest(body: 'Missing required parameters');
  }

  final db = await connectToDb();
  print(buildHash);
  print(user['user_id']);

  // Проверяем, существует ли сборка и принадлежит ли она текущему пользователю
  final buildResult = await db.query(
    'SELECT * FROM builds WHERE hash = @hash AND user_id = @user_id',
    substitutionValues: {
      'hash': buildHash,
      'user_id': user['user_id'],
    },
  );

  if (buildResult.isEmpty) {
    return Response.notFound('Build not found or unauthorized');
  }

  // Удаляем компонент из сборки
  await db.query(
    'DELETE FROM build_components WHERE build_id = (SELECT id FROM builds WHERE hash = @hash) AND component_id = @component_id',
    substitutionValues: {
      'hash': buildHash,
      'component_id': componentId,
    },
  );

  await db.close();

  return Response.ok('Component removed successfully');
}

