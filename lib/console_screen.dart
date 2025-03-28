import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'log_provider.dart';

class ConsoleLogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Console Logs"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: logProvider.clearLogs,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: logProvider.logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              logProvider.logs[index],
              style: TextStyle(
                color: _getLogColor(logProvider.logs[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains("ERROR")) {
      return Colors.red;
    } else if (log.contains("WARNING")) {
      return Colors.orange;
    }
    return Colors.black;
  }
}
