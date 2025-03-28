import 'package:flutter/material.dart';

class LogProvider extends ChangeNotifier {
  final List<String> _logs = [];

  List<String> get logs => _logs;

  void addLog(String log) {
    _logs.add(log);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
