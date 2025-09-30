import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_api/controllers/controllers.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

final List<EnvVar> _required = <EnvVar>[
  EnvVar.databaseKey,
  EnvVar.databaseUrl,
  EnvVar.pathTibiaArchive,
  EnvVar.pathTibiaArchiveApi,
  EnvVar.pathTibiaDataApi,
  EnvVar.pathTibiaDataApiSelfHosted,
];
late final Env _env;
late final IDatabaseClient _databaseClient;
final IHttpClient _httpClient = MyDioClient();

final IBazaarController _bazaarCtrl = BazaarController(_databaseClient);
final IBooksController _booksCtrl = BooksController(_env, _httpClient);
final ILiveStreamsController _liveStreamsCtrl = LiveStreamsController(_databaseClient, _httpClient);
final INPCsController _npcsCtrl = NPCsController(_env, _httpClient);
final IOnlineController _onlineCtrl = OnlineController(_databaseClient);
final SettingsController _settingsCtrl = SettingsController(_databaseClient);
final UserController _userCtrl = UserController(_env, _databaseClient, _httpClient);
final HighscoresController _highscoresCtrl = HighscoresController(
  _env,
  _databaseClient,
  _httpClient,
  _onlineCtrl,
);
final CharacterController _characterCtrl = CharacterController(_env, _databaseClient, _httpClient, _highscoresCtrl);

// Configure routes.
final Router _router = Router()
  ..get('/bazaar', _bazaarCtrl.get)
  ..get('/books', _booksCtrl.getAll)
  ..get('/character/<name>', _characterCtrl.get)
  ..get('/highscores/<world>/<category>/<page>', _highscoresCtrl.get)
  ..get('/highscores/overview', _highscoresCtrl.overview)
  ..get('/livestreams', _liveStreamsCtrl.get)
  ..get('/npcs', _npcsCtrl.getAll)
  ..get('/npcs/<name>', _npcsCtrl.getTranscripts)
  ..get('/online/now', _onlineCtrl.getOnlineNow)
  ..get('/online/time/<date>', _onlineCtrl.getOnlineTime)
  ..get('/settings/<value>', _settingsCtrl.get)
  ..post('/user/signin', _userCtrl.signin)
  ..post('/user/signup', _userCtrl.signup)
  ..post('/user/verify', _userCtrl.verify);

Future<void> _loadEnv() async {
  Map<String, String> localMap = <String, String>{}..addAll(Platform.environment);
  final DotEnv dotEnv = DotEnv();
  dotEnv.load();
  // ignore: invalid_use_of_visible_for_testing_member
  localMap.addAll(dotEnv.map);
  _env = Env(env: localMap, required: _required);
}

void main(List<String> args) async {
  await _loadEnv();
  _databaseClient = MySupabaseClient(
    databaseUrl: _env[EnvVar.databaseUrl]!,
    databaseKey: _env[EnvVar.databaseKey]!,
  );

  // Use any available host or container IP (usually `0.0.0.0`).
  final InternetAddress ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final Handler handler = Pipeline().addMiddleware(corsHeaders()).addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final HttpServer server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
