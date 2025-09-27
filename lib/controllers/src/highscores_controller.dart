import 'package:forgottenlandapp_adapters/adapters.dart';
import 'package:forgottenlandapp_models/models.dart';
import 'package:forgottenlandapp_utils/utils.dart';
import 'package:shelf/shelf.dart';

import '../../utils/utils.dart';
import '../controllers.dart';

class HighscoresController {
  HighscoresController(
    this.env,
    this.databaseClient,
    this.httpClient,
    this.onlineCtrl,
  );

  final Env env;
  final IDatabaseClient databaseClient;
  final IHttpClient httpClient;
  final IOnlineController onlineCtrl;

  Future<Response> get(Request request, String world, String category, String page) async {
    int pageAux = int.tryParse(page) ?? 1;

    if (category.contains('experiencegained')) return getExpGain(world, category, pageAux);
    if (category.contains('onlinetime')) return getOnlineTime(world, category, pageAux);
    if (category.contains('rookmaster')) return getRookmaster(world, pageAux);
    return getFromTibiaData(world, category, pageAux);
  }

  Future<Response> getFromTibiaData(String? world, String? category, int page) async {
    try {
      Record? record = await _getFromTibiaData(world, category, page);
      if (record == null) return ApiResponse.noContent();
      return ApiResponse.success(data: record.toJson());
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Record?> _getFromTibiaData(String? world, String? category, int page) async {
    MyHttpResponse response = await httpClient.get(
      '${env['PATH_TIBIA_DATA_SELFHOSTED']}/highscores/$world/$category/none/$page',
    );
    if (!response.success) return null;
    if (response.dataAsMap['highscores'] is! Map<String, dynamic>) return null;

    Record record = Record.fromJson(response.dataAsMap['highscores'] as Map<String, dynamic>);
    if (record.list.isEmpty) return null;
    return record;
  }

  List<T> _filterWorld<T>(String world, List<T> list) {
    if (world == 'all') return list;
    if (list is List<OnlineEntry>) {
      list.removeWhere((T e) => (e as OnlineEntry).world?.toLowerCase() != world);
    } else if (list is List<HighscoresEntry>) {
      list.removeWhere((T e) => (e as HighscoresEntry).world?.name?.toLowerCase() != world);
    }
    return list;
  }

  List<T> _addMissingRank<T>(int? page, List<T> list) {
    if (list.isEmpty) return list;
    int offset = page == null ? 0 : 50 * (page - 1);
    if (list is List<HighscoresEntry>) {
      for (T e in list) {
        (e as HighscoresEntry).rank = list.indexOf(e) + 1 + offset;
      }
    } else if (list is List<OnlineEntry>) {
      for (T e in list) {
        (e as OnlineEntry).rank = list.indexOf(e) + 1 + offset;
      }
    }
    return list;
  }

  Future<Response> getExpGain(String world, String category, int? page) async {
    String? table = tableFromCategory[category];

    if (page != null && page <= 0) return ApiResponse.error('Invalid page number');
    if (table == null) return ApiResponse.error('Invalid category');

    try {
      Record? record = await localGetExpGain(world, category, page);
      if (record == null) return ApiResponse.noContent();
      return ApiResponse.success(data: record.toJson());
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Record?> localGetExpGain(String world, String category, int? page) async {
    String table = tableFromCategory[category]!;
    Map<String, Object> query = queryFromCategory[category]!;
    dynamic response = await databaseClient.from(table).select().match(query).maybeSingle();
    if (response is! Map<String, dynamic>) return null;
    if (response['data'] is! Map<String, dynamic>) return null;

    Record record = Record.fromJson(response['data'] as Map<String, dynamic>);
    record.timestamp = response['timestamp'] as String?;
    record.list = _filterWorld<HighscoresEntry>(world, record.list);
    if (page != null) record.list = record.list.getSegment<HighscoresEntry>(size: 50, index: page - 1);
    record.list = _addMissingRank<HighscoresEntry>(page, record.list);

    if (record.list.isEmpty) return null;
    return record;
  }

  Future<Response> getOnlineTime(String world, String category, int? page) async {
    String? table = tableFromCategory[category];

    if (page != null && page <= 0) return ApiResponse.error('Invalid page number');
    if (table == null) return ApiResponse.error('Invalid category');

    try {
      Online? online = await localGetOnlineTime(world, category, page);
      if (online == null) return ApiResponse.noContent();
      return ApiResponse.success(data: online.toJson());
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Online?> localGetOnlineTime(String world, String category, int? page) async {
    String? table = tableFromCategory[category]!;
    Map<String, Object> query = queryFromCategory[category]!;
    dynamic response = await databaseClient.from(table).select().match(query).maybeSingle();
    if (response is! Map<String, dynamic>) return null;
    if (response['data'] is! Map<String, dynamic>) return null;

    Online online = Online.fromJson(response['data'] as Map<String, dynamic>);
    online.list = _filterWorld<OnlineEntry>(world, online.list);
    if (page != null) online.list = online.list.getSegment<OnlineEntry>(size: 50, index: page - 1);
    online.list = _addMissingRank<OnlineEntry>(page, online.list);

    if (online.list.isEmpty) return null;
    return online;
  }

  Future<Response> getRookmaster(String world, int? page) async {
    if (page != null && page < 0) return ApiResponse.error('Invalid page number');

    try {
      Record? record = await localGetRookmaster(world, page);
      if (record == null) return ApiResponse.noContent();
      return ApiResponse.success(data: record.toJson());
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Record?> localGetRookmaster(String world, int? page) async {
    dynamic response = await databaseClient.from('rook-master').select().order('date').limit(1).maybeSingle();
    if (response == null) return null;

    Record record = Record.fromJson(response['data'] as Map<String, dynamic>);
    record.timestamp = response['timestamp'] as String?;
    record.list = _filterWorld<HighscoresEntry>(world, record.list);
    if (page != null) record.list = record.list.getSegment<HighscoresEntry>(size: 50, index: page - 1);
    record.list = _addMissingRank<HighscoresEntry>(page, record.list);

    if (record.list.isEmpty) return null;
    return record;
  }

  Future<Response> overview(Request request) async {
    try {
      Online? rOnlinetime = await localGetOnlineTime('all', 'onlinetime+today', 1);
      Record? rExpgain = await localGetExpGain('all', 'experiencegained+today', 1);
      Record? rRookmaster = await localGetRookmaster('all', 1);
      Record? rExperience = await _getFromTibiaData('all', 'experience', 1);
      Online? rOnline = await onlineCtrl.onlineNow();

      if (rOnline != null) {
        for (OnlineEntry online in rOnline.list) {
          if (rOnlinetime?.list.any((OnlineEntry e) => e.name == online.name) ?? false) {
            rOnlinetime?.list.firstWhere((OnlineEntry e) => e.name == online.name).isOnline = true;
          }
          if (rExpgain?.list.any((HighscoresEntry e) => e.name == online.name) ?? false) {
            rExpgain?.list.firstWhere((HighscoresEntry e) => e.name == online.name).isOnline = true;
          }
          if (rRookmaster?.list.any((HighscoresEntry e) => e.name == online.name) ?? false) {
            rRookmaster?.list.firstWhere((HighscoresEntry e) => e.name == online.name).isOnline = true;
          }
          if (rExperience?.list.any((HighscoresEntry e) => e.name == online.name) ?? false) {
            rExperience?.list.firstWhere((HighscoresEntry e) => e.name == online.name).isOnline = true;
          }
        }
      }

      Overview overview = Overview(
        experiencegained: _overviewSublist<HighscoresEntry>(rExpgain?.list),
        onlinetime: _overviewSublist<OnlineEntry>(rOnlinetime?.list),
        rookmaster: _overviewSublist<HighscoresEntry>(rRookmaster?.list),
        experience: _overviewSublist<HighscoresEntry>(rExperience?.list),
        online: _overviewSublist<OnlineEntry>(rOnline?.list, length: 25),
        timestamp: DT.tibia.timeStamp(),
      );
      return ApiResponse.success(data: overview.toJson());
    } catch (e) {
      return handleError(e);
    }
  }

  List<E> _overviewSublist<E>(List<E>? list, {int length = 5}) {
    if (list == null) return <E>[];
    if (list.length <= length) return list;
    return list.sublist(0, length);
  }
}
