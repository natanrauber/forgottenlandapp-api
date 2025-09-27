import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

abstract class ILiveStreamsController {
  Future<Response> get(Request request);
}

class LiveStreamsController implements ILiveStreamsController {
  LiveStreamsController(this.databaseClient, this.httpClient);

  final IDatabaseClient databaseClient;
  final IHttpClient httpClient;

  @override
  Future<Response> get(Request request,
      {int attempt = 1, MyHttpResponse? tokenResponse, MyHttpResponse? gameResponse}) async {
    if (attempt > 3) return ApiResponse.success();

    try {
      dynamic verifiedStreams = await databaseClient.from('verified-livestreams').select();

      tokenResponse ??= await httpClient.post(
        'https://id.twitch.tv/oauth2/token',
        <String, dynamic>{
          'client_id': 'ne337fiw9eq9dl3oaq0h95m49iuaa3',
          'client_secret': 'szxzatc7l36syf2l1b4yvqaw7vn0a3',
          'grant_type': 'client_credentials',
        },
      );
      gameResponse ??= await httpClient.get(
        'https://api.twitch.tv/helix/games?name=Tibia',
        headers: <String, dynamic>{
          'Authorization': 'Bearer ${tokenResponse.dataAsMap['access_token']}',
          'Client-Id': 'ne337fiw9eq9dl3oaq0h95m49iuaa3',
        },
      );

      MyHttpResponse? streamsResponse;
      List<LiveStream> streams = <LiveStream>[];
      do {
        String? cursor;
        if (streamsResponse != null) cursor = streamsResponse.dataAsMap['pagination']['cursor'];
        String url = 'https://api.twitch.tv/helix/streams?game_id=${gameResponse.dataAsMap['data'][0]['id']}&first=100';
        if (cursor != null) url = '$url&after=$cursor';
        streamsResponse = await httpClient.get(
          url,
          headers: <String, dynamic>{
            'Authorization': 'Bearer ${tokenResponse.dataAsMap['access_token']}',
            'Client-Id': 'ne337fiw9eq9dl3oaq0h95m49iuaa3',
          },
        );
        for (dynamic e in streamsResponse.dataAsMap['data'] as List<dynamic>) {
          LiveStream stream = LiveStream();
          if (e is Map<String, dynamic>) stream = LiveStream.fromJson(e);
          if (stream.contains('Rookgaard') && !streams.any((LiveStream e) => e.userName == stream.userName)) {
            if (_isVerified(verifiedStreams, stream)) stream.tags.insert(0, 'Verified');
            streams.add(stream);
          }
        }
      } while ((streamsResponse.dataAsMap['data'] as List<dynamic>).isNotEmpty);

      if (streams.isEmpty) {
        return get(
          request,
          attempt: attempt + 1,
          tokenResponse: tokenResponse.success ? tokenResponse : null,
          gameResponse: gameResponse.success ? gameResponse : null,
        );
      }

      return ApiResponse.success(data: streams);
    } catch (e) {
      return ApiResponse.error(e);
    }
  }

  bool _isVerified(dynamic verifiedStreams, LiveStream stream) {
    stream.tags.removeWhere((String e) => e.toLowerCase() == 'verified');
    if (verifiedStreams is! List<dynamic>) return false;
    for (dynamic e in verifiedStreams) {
      if (e is Map<String, dynamic> &&
          e['name'] is String &&
          e['name'].toLowerCase() == stream.userName?.toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
