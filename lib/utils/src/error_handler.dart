import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

Response handleError(Object e) {
  if (e.toString().contains('Results contain 0 rows')) return ApiResponse.noContent();
  return ApiResponse.error(e);
}
