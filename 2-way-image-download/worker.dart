import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'extension.dart';

enum Command { process, download, shutdown }

enum Response { validate, result }

class Worker {
  final SendPort _commands;
  final ReceivePort _responses;
  final List<String> _allowedDomains;
  final Map<int, Completer<dynamic>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Worker._(this._responses, this._commands, this._allowedDomains) {
    _responses.listen(_handleIsolateResponses);
  }

  Future<void> processUrls(List<String> urls) async {
    for (final url in urls) {
      await _sendCommandToWorker(.process, (url, urls.length));
    }
  }

  void close() {
    if (!_closed) {
      _closed = true;

      if (_activeRequests.isEmpty) {
        print('--- closing port --');
        _commands.send(Command.shutdown);
        _responses.close();
      }
    }
  }

  bool _validateUrl(String url) {
    try {
      final host = url.toUri().host;
      return _allowedDomains.any((domain) => host.contains(domain));
    } catch (e, st) {
      print('[MAIN] [_validateUrl] [ERROR] $e\nStack Trace:\n$st');
      return false;
    }
  }

  Future<dynamic> _sendCommandToWorker(Command command, dynamic data) async {
    final completer = Completer<dynamic>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((command, id, data));
    return await completer.future;
  }

  void _handleIsolateResponses(dynamic message) {
    switch (message) {
      case (Response.validate, String url, int current, int total):
        print(
          '[MAIN] [_handleIsolateResponses] Progress: $current/$total processed',
        );
        _commands.send((Command.download, (url, _validateUrl(url))));
      case (Response.result, int id, dynamic status):
        final completer = _activeRequests.remove(id)!;
        print('[MAIN] [_handleIsolateResponses] Status: $status');
        if (status case Error || Exception) {
          completer.completeError(status);
        } else {
          completer.complete(status);
        }
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static Future<Worker> spawn(List<String> allowedDomains) async {
    final initPort = RawReceivePort(null, 'MAIN-ISOLATE');
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final responsePort = ReceivePort.fromRawReceivePort(initPort);
      final commandPort = initialMessage as SendPort;
      connection.complete((responsePort, commandPort));
    };

    try {
      await Isolate.spawn(_handleIsolateStart, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (responsePort, commandPort) = await connection.future;
    return ._(responsePort, commandPort, allowedDomains);
  }

  static void _handleIsolateStart(SendPort sp) {
    final rp = ReceivePort('WORKER-ISOLATE');
    sp.send(rp.sendPort);
    _handleIsolateMessages(rp, sp);
  }

  static void _handleIsolateMessages(ReceivePort rp, SendPort sp) {
    int processed = 0;
    int currentCompleterId = 0;

    rp.listen((message) {
      switch (message) {
        case (Command.shutdown):
          rp.close();
        case (Command.process, int id, (String url, int total)):
          print(
            '[WORKER [_handleIsolateMessages] Requesting validation for: $url',
          );
          currentCompleterId = id;
          sp.send((Response.validate, url, ++processed, total));
        case (Command.download, (String url, bool isValid)):
          print(
            '[WORKER] [_handleIsolateMessages] Received validation for $url: $isValid',
          );
          if (isValid) {
            _downloadImage(url.toUri())
                .then(
                  (status) =>
                      sp.send((Response.result, currentCompleterId, status)),
                )
                .onError((err, st) {
                  sp.send((Response.result, currentCompleterId, err));
                  print(
                    '[WORKER] [_handleIsolateMessages] Failed to download: $err\nStack Trace:\n$st',
                  );
                });
          } else {
            sp.send((
              Response.result,
              currentCompleterId,
              {'status': 'skipped'},
            ));
          }
      }
    });
  }

  static Future<Map<String, dynamic>> _downloadImage(
    Uri uri, {
    String outputDirPath = "images",
    int randomRange = 100,
    Duration requestDelay = const Duration(milliseconds: 10),
  }) async {
    final client = HttpClient();
    final totalBars = 20;
    final terminalWidth = stdout.hasTerminal ? stdout.terminalColumns : 80;
    print('[_downloadImage] Downloading $uri');

    try {
      final conn = await client.getUrl(uri);
      final response = await conn.close();
      if (response.statusCode == 200) {
        var imgResponse = response;
        if (response.redirects.isNotEmpty) {
          final redConn = await client.getUrl(
            response.redirects.first.location,
          );
          imgResponse = await redConn.close();
        }

        final data = <int>[];

        final totalSize = imgResponse.contentLength;
        final extension = imgResponse.headers.contentType?.subType ?? 'jpg';
        final contentDisposition = imgResponse.headers
            .value('Content-Disposition')
            ?.replaceAll('"', '');
        final filenameIndex = contentDisposition?.indexOf('filename=');
        final filename = filenameIndex != null && filenameIndex != -1
            ? contentDisposition!.substring(filenameIndex + 9)
            : 'image-${Random().nextInt(randomRange)}.$extension';

        await for (final chunk in imgResponse) {
          data.addAll(chunk);

          final progress = ((data.length / totalSize) * totalBars).round();
          final progressBar =
              ('█' * progress).padRight(totalBars) +
              ' | ${data.length.formatByteSize()}';
          stdout.write(
            '\r[_downloadImage] $filename'.padRight(
                  terminalWidth - progressBar.runes.length,
                ) +
                progressBar,
          );

          await Future.delayed(requestDelay);
        }
        print('');

        final dir = Directory(outputDirPath);
        if (!await dir.exists()) {
          print('[_downloadImage] Output directory created: $outputDirPath');
          await dir.create();
        }

        final file = File(
          outputDirPath.isEmpty ? filename : '$outputDirPath/$filename',
        );
        print('[_downloadImage] [WRITING TO DISK] ${file.path}');
        await file.writeAsBytes(data, flush: true);
        return {'status': 'downloaded'};
      } else {
        print(
          '[_downloadImage] Failed to download. Status Code: ${response.statusCode}',
        );
        return {'status': 'failed to downloaded'};
      }
    } on Object {
      rethrow;
    }
  }
}
