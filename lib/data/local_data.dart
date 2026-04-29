

import 'package:flutter/foundation.dart';

final localData = LocalData();

class LocalData {
  int currentUserID = 0;
  String currentUserName = '';
  String currentUserMobile = '';
  // String cosId = '210000';
  String token = '';

  // For Project :
  static String platformKey = kIsWeb
      ? '3'
      : (defaultTargetPlatform == TargetPlatform.android
          ? '1'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? '2'
              : '0');

  static String countryCode = '91';
}
