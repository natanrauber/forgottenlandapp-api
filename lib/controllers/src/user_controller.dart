import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

class UserController {
  UserController(this.env, this.databaseClient, this.httpClient);

  final Env env;
  final IDatabaseClient databaseClient;
  final IHttpClient httpClient;

  Future<Response> signup(Request request) async {
    try {
      dynamic requestData = jsonDecode(await request.readAsString());
      dynamic name = requestData['name'];
      dynamic secret = requestData['secret'];

      List<dynamic> response = await databaseClient.from('account').select().eq('name', name);
      if (response.isNotEmpty && response.first['verified'] == true) return ApiResponse.conflict();

      String code = 'FL:${generateRandomCode()}';
      Map<String, dynamic> account = <String, dynamic>{
        'name': name,
        'secret': secret,
        'code': code,
        'verified': false,
        'subscriber': false,
      };

      await databaseClient.from('account').upsert(account).match(<String, Object>{'name': name});

      Map<String, dynamic> data = <String, dynamic>{'code': code};
      return ApiResponse.success(data: data);
    } catch (e) {
      return ApiResponse.error(e);
    }
  }

  String generateRandomCode() {
    const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();

    return String.fromCharCodes(Iterable<int>.generate(
      20,
      (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ));
  }

  Future<Response> verify(Request request) async {
    try {
      dynamic requestData = jsonDecode(await request.readAsString());
      dynamic name = requestData['name'];

      MyHttpResponse r = await httpClient.get('${env[EnvVar.pathTibiaDataApi]}/character/$name');
      if (!r.success) return ApiResponse.notFound();

      print(JsonEncoder.withIndent(' ').convert(r.dataAsMap));
      String comment = r.dataAsMap['character']['character']['comment'];

      List<dynamic> response = await databaseClient.from('account').select().eq('name', name);
      if (response.isEmpty) return ApiResponse.notFound();
      if (response.first['verified'] == true) return ApiResponse.accepted();
      if (!comment.contains(response.first['code'])) return ApiResponse.notAcceptable();

      await databaseClient.from('account').update(<String, Object>{
        'verified': true,
      }).match(<String, Object>{
        'name': name,
      });
      return ApiResponse.success();
    } catch (e) {
      return ApiResponse.error(e);
    }
  }

  Future<Response> signin(Request request) async {
    try {
      dynamic requestData = jsonDecode(await request.readAsString());
      dynamic name = requestData['name'];
      dynamic secret = requestData['secret'];

      List<dynamic> response = await databaseClient.from('account').select().eq('name', name);
      if (response.isEmpty) return ApiResponse.notAcceptable();

      dynamic account = response.first;
      if (account['secret'] != secret) return ApiResponse.notAcceptable();

      User user = User.fromJson(account);
      user.token = sha256.convert(utf8.encode(name + DT.tibia.today())).toString();

      await databaseClient.from('session').upsert(<String, Object>{
        'name': user.name!,
        'date': DT.tibia.today(),
        'token': user.token!,
      }).match(<String, Object>{'name': name});

      return ApiResponse.success(data: user.toJson());
    } catch (e) {
      return ApiResponse.error(e);
    }
  }
}
