import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

abstract class IOnlineController {
  Future<Response> getOnlineNow(Request request);
  Future<Online?> onlineNow();
  Future<Response> getOnlineTime(Request request, String date);
}

class OnlineController implements IOnlineController {
  OnlineController(this.databaseClient);

  final IDatabaseClient databaseClient;

  @override
  Future<Response> getOnlineNow(Request request) async {
    try {
      Online? online = await onlineNow();
      if (online == null) return ApiResponse.noContent();
      return ApiResponse.success(data: online.toJson());
    } catch (e) {
      return ApiResponse.error(e);
    }
  }

  @override
  Future<Online?> onlineNow() async {
    dynamic response = await databaseClient.from('online').select().maybeSingle();
    if (response == null) return null;
    return Online.fromJson((response['data'] as Map<String, dynamic>));
  }

  @override
  Future<Response> getOnlineTime(Request request, String date) async {
    try {
      dynamic response = await databaseClient.from('onlinetime').select().eq('date', date).maybeSingle();
      if (response == null) return ApiResponse.noContent();
      Online online = Online.fromJson((response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{});
      return ApiResponse.success(data: online.toJson());
    } catch (e) {
      return ApiResponse.error(e);
    }
  }
}
