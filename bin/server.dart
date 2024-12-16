import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';
import 'package:shelf_static/shelf_static.dart';
import 'routes.dart';

Future<void> main() async {
  // Настраиваем Swagger UI
  final swaggerHandler = SwaggerUI(
    './docs/swagger.yaml', // Путь к Swagger YAML
    title: 'PC Configurator API',
    deepLink: true,
    docExpansion: DocExpansion.list,
  );

  // Настраиваем маршруты
  final router = setupRouter();

  // Статический обработчик для документации
  final staticHandler = createStaticHandler('bin/docs', defaultDocument: 'swagger.yaml');

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(
    (Router()
      ..mount('/', router.call)
      ..get('/docs/*', swaggerHandler.call)
      ..all('/docs/swagger.yaml', staticHandler)).call, // Обслуживание swagger.yaml
  );

  // Запуск сервера
  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on http://${server.address.host}:${server.port}');
}
