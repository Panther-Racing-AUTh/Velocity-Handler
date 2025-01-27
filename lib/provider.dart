import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

enum AppPlatform {
  web(1),
  android(2),
  ios(3),
  windows(4),
  macos(5),
  linux(6),
  unknown(0);

  final int value;

  const AppPlatform(this.value);
}

AppPlatform getPlatform() {
  if (kIsWeb) {
    return AppPlatform.web;
  } else if (Platform.isAndroid) {
    return AppPlatform.android;
  } else if (Platform.isIOS) {
    return AppPlatform.ios;
  } else if (Platform.isWindows) {
    return AppPlatform.windows;
  } else if (Platform.isMacOS) {
    return AppPlatform.macos;
  } else if (Platform.isLinux) {
    return AppPlatform.linux;
  } else {
    return AppPlatform.unknown;
  }
}

/// Returns the integer value of the current platform
int getPlatformValue() {
  return getPlatform().value;
}



// RPMRangeProvider to manage state of the ranges
class RPMRangeProvider with ChangeNotifier {
  final double minRange = 0;
  final double maxRange = 14000;
  int _rpmFrequencyFetchIndex = 0;
  bool _isMenuVisible = false; // Tracks menu visibility

  int _appIndex=1;
  final List<String> _options = ['High', 'Middle', 'Slow'];
  final List<int> _optionVals=[50,100,200];


  // Initial ranges
  List<double> _ranges = [0, 3000,5000 ,8000, 14000];
  List<int> _modePath = [1,2,3,4,3,2,1];

  List<double> get ranges => _ranges;
  int get rpmFrequencyFetchIndex => _rpmFrequencyFetchIndex;
  List<String> get options => _options;
  List<int> get optionVals => _optionVals;
  List<int> get modePath => _modePath;
  int get appIndex => _appIndex;
  bool get isMenuVisible => _isMenuVisible;


  void initializeAppIndex(int newAppIndex) {
    _appIndex=newAppIndex;
  }
  void updateMenuVisible(bool newMenuVisible) {
    _isMenuVisible=!newMenuVisible;
    notifyListeners();
  }


  void updateAppIndex(int newAppIndex) {
    _appIndex=newAppIndex;
    notifyListeners();
  }

  void updateModePath(List<int> newModePath) {
    _modePath=newModePath;
    notifyListeners();
  }

  void updateSelectedIndex(int selectedIndex) {
    _rpmFrequencyFetchIndex=selectedIndex;
    notifyListeners();
  }
  void updateAllRanges(List<double> newRanges) {
    _ranges = newRanges;
    notifyListeners();
  }


  int getModeFromRPM(double rpm) {
    for (int i = 1; i < _ranges.length; i++) {
      if (rpm >= _ranges[i-1] && rpm <= _ranges[i]) {
        return i; // Mode starts from 1
      }
    }
    return 0; // Return 0 if no range matches
  }
  // Update range and notify listeners

  // Save ranges as JSON string
  String saveRangesToJson() {
    List<Map<String, double>> rangesJson = [];
    for (int i = 0; i < _ranges.length - 1; i += 1) {
      rangesJson.add({"start": _ranges[i], "end": _ranges[i + 1]});
    }
    return jsonEncode({"ranges": rangesJson});
  }
}
