import 'package:shelf_router/shelf_router.dart';
import 'handlers/temporary_user_handler.dart';
import 'handlers/build_handler.dart';
import 'handlers/build_component_handler.dart';
import 'handlers/components_handler.dart';
import 'handlers/authorize_user_handler.dart';

Router setupRouter() {
  final router = Router();

  router.get('/components', handleGetComponents);
  router.post('/add_user', addAuthorizedUser);
  router.post('/temporary_user', addTemporaryUser);  // Добавление временного пользователя
  router.post('/create_build', createNewBuild);  // Инициализация новой сборки
  router.get('/get_build', getBuildComponentsByHash);
  router.get('/get_shared_build', getSharedBuild);
  router.get('/get_shared_link', getSharedLink);
  router.post('/add_component', addComponentToBuild);  // Добавление компонента в сборку
  router.delete('/remove_component', removeComponentFromBuild);  // Удаление компонента из сборки

  return router;
}

