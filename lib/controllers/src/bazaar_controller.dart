import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';
import 'package:universal_html/controller.dart';

abstract class IBazaarController {
  Future<Response> get(Request request);
}

class BazaarController implements IBazaarController {
  BazaarController(this.databaseClient);

  final IDatabaseClient databaseClient;

  @override
  Future<Response> get(Request request) async {
    try {
      int page = 1;
      Bazaar bazaar = Bazaar();
      List<dynamic> auctions = <dynamic>[];
      List<dynamic> auxList = <dynamic>[];

      final WindowController controller = WindowController();

      do {
        auxList.clear();
        await controller.openHttp(
          method: 'GET',
          uri: Uri.parse(
            'https://www.tibia.com/charactertrade/?subtopic=currentcharactertrades&filter_profession=1&currentpage=$page',
          ),
        );
        auxList.addAll(controller.window.document.querySelectorAll('div.Auction').toList());
        auctions.addAll(auxList.toList());
        page++;
      } while (auctions.length % 25 == 0 && auxList.isNotEmpty);

      bazaar = Bazaar.fromListDivElement(auctions);

      return ApiResponse.success(data: bazaar.toJson());
    } catch (e) {
      return ApiResponse.error(e);
    }
  }
}
