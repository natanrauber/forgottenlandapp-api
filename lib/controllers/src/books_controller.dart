import 'dart:convert';

import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

abstract class IBooksController {
  Future<Response> getAll(Request request);
}

class BooksController implements IBooksController {
  BooksController(this.env, this.httpClient);

  final Env env;
  final IHttpClient httpClient;
  late final String? pathTibiaArchive;

  @override
  Future<Response> getAll(Request request) async {
    try {
      MyHttpResponse response = await httpClient.get(
        '${env[EnvVar.pathTibiaArchive]}/data/books/book_database.json',
      );
      response.data = jsonDecode(response.data);

      List<dynamic> filteredList = <dynamic>[];
      for (dynamic e in response.dataAsList) {
        if (e is Map<String, dynamic>) {
          if (e['locations'] is List<dynamic>) {
            if ((e['locations'] as List<dynamic>)
                .any((dynamic element) => element is String && element.toLowerCase().contains('rookgaard'))) {
              filteredList.add(e);
            }
          }
        }
      }

      return ApiResponse.success(data: filteredList);
    } catch (e) {
      return ApiResponse.error(e);
    }
  }
}
