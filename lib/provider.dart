import 'package:flutter/material.dart';
import 'dart:convert';

// RPMRangeProvider to manage state of the ranges
class RPMRangeProvider with ChangeNotifier {
  final double minRange = 0;
  final double maxRange = 14000;
  int _rpmFrequencyFetchIndex = 0;
  final List<String> _quality = ["High",'low'];
  final List<String> _options = ['High', 'Middle', 'Slow'];
  final List<int> _optionVals=[100,150,200];


  // Initial ranges
  List<int> _ranges = [0, 3000,5000 ,8000, 14000];
  List<int> _modePath = [1,2,3,4,3,2,1];

  List<int> get ranges => _ranges;
  int get rpmFrequencyFetchIndex => _rpmFrequencyFetchIndex;
  List<String> get options => _options;
  List<int> get optionVals => _optionVals;
  List<int> get modePath => _modePath;

  void updateModePath(List<int> newModePath) {
    _modePath=newModePath;
    notifyListeners();
  }

  void updateSelectedIndex(int selectedIndex) {
    _rpmFrequencyFetchIndex=selectedIndex;
    notifyListeners();
  }
  void updateAllRanges(List<int> newRanges) {
    _ranges = newRanges;
    notifyListeners();
  }


  int getModeFromRPM(int rpm) {
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
    List<Map<String, int>> rangesJson = [];
    for (int i = 0; i < _ranges.length - 1; i += 1) {
      rangesJson.add({"start": _ranges[i], "end": _ranges[i + 1]});
    }
    return jsonEncode({"ranges": rangesJson});
  }
}
