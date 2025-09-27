import 'package:forgottenlandapp_utils/utils.dart';

Map<String, Map<String, Object>> get queryFromCategory => <String, Map<String, Object>>{
      'experiencegained+today': <String, Object>{'date': DT.tibia.today()},
      'experiencegained+yesterday': <String, Object>{'date': DT.tibia.yesterday()},
      'experiencegained+last7days': <String, Object>{'period': '7days', 'date': DT.tibia.yesterday()},
      'experiencegained+last30days': <String, Object>{'period': '30days', 'date': DT.tibia.yesterday()},
      'experiencegained+last365days': <String, Object>{'period': '365days', 'date': DT.tibia.yesterday()},
      'onlinetime+today': <String, Object>{'date': DT.tibia.today()},
      'onlinetime+yesterday': <String, Object>{'date': DT.tibia.yesterday()},
      'onlinetime+last7days': <String, Object>{'date': DT.tibia.yesterday()},
      'onlinetime+last30days': <String, Object>{'date': DT.tibia.yesterday()},
      'onlinetime+last365days': <String, Object>{'date': DT.tibia.yesterday()},
    };

Map<String, String> get tableFromCategory => <String, String>{
      'experiencegained+today': 'exp-gain-today',
      'experiencegained+yesterday': 'exp-gain-last-day',
      'experiencegained+last7days': 'exp-gain-period',
      'experiencegained+last30days': 'exp-gain-period',
      'experiencegained+last365days': 'exp-gain-period',
      'onlinetime+today': 'onlinetime',
      'onlinetime+yesterday': 'onlinetime',
      'onlinetime+last7days': 'onlinetime-last7days',
      'onlinetime+last30days': 'onlinetime-last30days',
      'onlinetime+last365days': 'onlinetime-last365days',
    };
