import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

import '../../utils/src/error_handler.dart';

class SettingsController {
  SettingsController(this.databaseClient);

  final IDatabaseClient databaseClient;

  Future<Response> get(Request request, String value) async {
    if (value.contains('features')) return _getFeatures();
    return ApiResponse.notFound();
  }

  Future<Response> _getFeatures() async {
    try {
      dynamic response = await databaseClient.from('features').select();
      return ApiResponse.success(data: response);
    } catch (e) {
      return handleError(e);
    }
  }
}
