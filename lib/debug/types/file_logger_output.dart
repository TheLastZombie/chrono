import 'dart:io';

import 'package:clock_app/app.dart';
import 'package:clock_app/common/data/paths.dart';
import 'package:clock_app/common/utils/snackbar.dart';
import 'package:logger/logger.dart';

class FileLoggerOutput extends LogOutput {
  FileLoggerOutput();

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      print(line);
    }

    String message = switch (event.origin.message.runtimeType) {
      String => event.origin.message as String,
      Exception => (event.origin.message as Exception).toString(),
      _ => "Unknown error",
    };

    _writeLog(message, event.level);

    Future(() {
      if (event.level == Level.error &&
          App.navigatorKey.currentContext != null) {
        showSnackBar(
            App.navigatorKey.currentContext!, message,
            error: true, navBar: false, fab: false);
      }
    });
  }

  Future<void> _writeLog(String message, Level level) async {
    final DateTime currentDate = DateTime.now();
    final String dateString =
        "${currentDate.day}-${currentDate.month}-${currentDate.year}";

    final File file = File(await getLogsFilePath());

    if (!(await file.exists())) {
      await file.create(recursive: true);
    }

    file.writeAsStringSync(
      "[$dateString | ${currentDate.hour}:${currentDate.minute}:${currentDate.second}] [${level.name}] $message\n",
      mode: FileMode.append,
    );
  }
}
