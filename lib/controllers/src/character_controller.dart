import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../utils/src/error_handler.dart';
import 'highscores_controller.dart';

typedef HE = HighscoresEntry;
typedef OE = OnlineEntry;

class CharacterController {
  CharacterController(this.env, this.databaseClient, this.httpClient, this.highscoresCtrl) {
    pathTibiaData = env[EnvVar.pathTibiaDataApi];
  }

  final Env env;
  final IDatabaseClient databaseClient;
  final IHttpClient httpClient;
  final HighscoresController highscoresCtrl;

  String? pathTibiaData;

  Future<Response> get(Request request) async {
    String? name = request.params['name']?.toLowerCase().replaceAll('%20', ' ');
    if (name == null) return ApiResponse.error('Missing param "name"');

    try {
      final MyHttpResponse response = await httpClient.get('$pathTibiaData/character/${name.replaceAll(' ', '%20')}');
      if (response.statusCode == 502) return ApiResponse.notFound();
      if (_notFound(name, response)) return ApiResponse.notFound();
      if (_notOnRookgaard(response)) return ApiResponse.notAcceptable();
      await _getExpGain(name, response);
      await _getOnlineTime(name, response);
      await _getRookmaster(name, response);
      return ApiResponse.success(data: response.dataAsMap['character']);
    } catch (e) {
      return handleError(e);
    }
  }

  bool _notFound(String name, MyHttpResponse response) =>
      response.dataAsMap['character']['character']['name']?.toString().toLowerCase() != name;

  bool _notOnRookgaard(MyHttpResponse response) =>
      response.dataAsMap['character']['character']['residence']?.toString().toLowerCase() != 'rookgaard';

  Future<void> _getExpGain(String name, MyHttpResponse res) async {
    res.dataAsMap['character']['experiencegained'] = <String, dynamic>{};
    List<String> timeframes = <String>['today', 'yesterday', 'last7days', 'last30days'];
    for (String tf in timeframes) {
      final Record? rec = await highscoresCtrl.localGetExpGain('all', 'experiencegained+$tf', null);
      if (rec == null) continue;
      for (HE e in rec.list) {
        if (e.match(name)) res.dataAsMap['character']['experiencegained'][tf] = e.toJson();
      }
    }
  }

  Future<void> _getOnlineTime(String name, MyHttpResponse res) async {
    res.dataAsMap['character']['onlinetime'] = <String, dynamic>{};
    List<String> timeframes = <String>['today', 'yesterday', 'last7days', 'last30days'];
    for (String tf in timeframes) {
      final Online? online = await highscoresCtrl.localGetOnlineTime('all', 'onlinetime+$tf', null);
      if (online == null) continue;
      for (OE e in online.list) {
        if (e.match(name)) res.dataAsMap['character']['onlinetime'][tf] = e.toJson();
      }
    }
  }

  Future<void> _getRookmaster(String name, MyHttpResponse res) async {
    final Record? rec = await highscoresCtrl.localGetRookmaster('all', null);
    if (rec == null) return;
    for (HE e in rec.list) {
      if (e.match(name)) res.dataAsMap['character']['rookmaster'] = e.toJson();
    }
  }
}
