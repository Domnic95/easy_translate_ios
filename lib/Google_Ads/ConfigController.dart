import 'dart:developer';

import 'package:easy_translate/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigController extends ChangeNotifier {
  bool isCall = false;

  static ConfigModel? _memo;
  static ConfigModel? get cached => _memo;
  int _adsShutdownRevision = 0;
  int get adsShutdownRevision => _adsShutdownRevision;

  Future<bool> fetchConfig() async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.configUrl),
            headers: {"Accept": "*/*"},
            body: {
              "packagename": AppConstants.packageName,
              "secretkey": AppConstants.apiSecretKey,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final configModel = configModelFromJson(response.body.toString());
        log(configModelToJson(configModel).toString());
        final prior = _memo?.extraParam.adsOnOff;
        _memo = configModel;
        if (prior == true && configModel.extraParam.adsOnOff == false) {
          _adsShutdownRevision++;
          log(
            '[ConfigController] adsOnOff flipped true→false; '
            'revision=$_adsShutdownRevision',
          );
        }
        await saveConfigToSharedPreferences(configModel);
        isCall = true;
        notifyListeners();
        return true;
      } else {
        isCall = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      log("Error fetching config: $e");
      isCall = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveConfigToSharedPreferences(ConfigModel configModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("configKey", configModelToJson(configModel));
    notifyListeners();
  }

  Future<ConfigModel?> getConfigFromSharedPreferences() async {
    if (_memo != null) return _memo;

    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString("configKey");
    if (configJson != null) {
      _memo = configModelFromJson(configJson);
      return _memo;
    }
    return null;
  }
}
