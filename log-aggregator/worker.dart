import 'dart:async';
import 'dart:isolate';

import 'extension.dart';

enum LogLevel { debug, info, warn, error, fatal }

typedef WorkerConfig = ({
  int workerId,
  String serviceName,
  Duration logRate,
  LogLevel minLevel,
});

typedef LogEntry = ({
  int workerId,
  DateTime timestamp,
  LogLevel logLevel,
  String serviceName,
  String message,
});

enum Command { pause, resume, changeLevel, requestStats, shutdown }

enum MessageType { logEntry, statusReport, statusUpdate }

const _dummy_auth_service_messages = [
  'User authentication successful',
  'Token generated',
  'Invalid token signature',
  'Session expired',
  'Password reset requested',
];

const _dummy_api_service_messages = [
  'Incoming request: GET /api/users',
  'Route matched',
  'Response sent: 200 OK',
  'Rate limit exceeded',
  'Invalid API key',
];

const _dummy_database_service_messages = [
  'Connection pool at 80% capacity',
  'Slow query detected',
  'Transaction committed',
  'Deadlock detected',
  'Connection timeout',
];

const _dummy_cache_service_messages = [
  'Cache hit rate: 94.2%',
  'Cache miss - fetching from DB',
  'Cache eviction triggered',
  'Memory usage: 75%',
  'Cache cleared',
];

const _unknown_service_messages = ['unknown service'];

class Worker {
  final Map<int, (ReceivePort, SendPort)> _workers;
  final Map<int, bool> _closedWorkers;
  final StreamController _controller;

  Worker._(this._workers)
    : _controller = StreamController(),
      _closedWorkers = {} {
    for (final MapEntry(:key, :value) in _workers.entries) {
      value.$1.listen(_handleIsolateWorkerResponses);
      _closedWorkers[key] = false;
    }
  }

  Future<void> simulateMultipleWorkers() async {
    final Map<LogLevel, int> aggregatedStats = {};
    final subscription = _controller.stream.listen((message) {
      final (MessageType type, int workerId, dynamic content) = message;
      switch (type) {
        case .logEntry:
          final entry = content as LogEntry;
          print('[W-$workerId] [LOG ENTRY] $entry');
          aggregatedStats.update(
            entry.logLevel,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        case (.statusReport):
          final stats = content as Map<LogLevel, int>;
          print('[W-$workerId] [STATS] $stats');
        case (.statusUpdate):
          final currStatus = content as String;
          print('[W-$workerId] [CURRENT STATE] $currStatus');
      }
    });

    await Future.delayed(Duration(seconds: 3));

    _workers[2]!.$2.send((Command.pause));

    await Future.delayed(Duration(seconds: 2));

    for (final MapEntry(:value) in _workers.entries) {
      value.$2.send((Command.requestStats));
    }

    await Future.delayed(Duration(seconds: 1));

    _workers[2]!.$2.send((Command.resume));

    await Future.delayed(Duration(seconds: 5));

    print('-- Aggregated Statistics --\n$aggregatedStats');

    for (final workerId in _workers.keys) {
      close(workerId);
    }

    await subscription.cancel();
  }

  void close(int workerId) {
    final entry = _workers[workerId];
    if (entry != null) {
      _closedWorkers[workerId] = true;
      entry.$2.send(Command.shutdown);
    }
  }

  void _handleIsolateWorkerResponses(dynamic message) {
    final (_, workerId, _) = message as (MessageType, int, dynamic);

    _controller.sink.add(message);

    if (_closedWorkers[workerId] == true) _workers.remove(workerId)!.$1.close();
  }

  static Future<Worker> spawnWorkers(List<WorkerConfig> configs) async {
    final workers = <int, (ReceivePort, SendPort)>{};
    for (final config in configs) {
      final workerId = config.workerId;
      final initPort = RawReceivePort(null, 'INIT_RECEIVE_PORT-$workerId');
      final connection = Completer<(ReceivePort, SendPort)>.sync();
      initPort.handler = (initMessage) {
        final rp = ReceivePort.fromRawReceivePort(initPort);
        final sp = initMessage as SendPort;
        connection.complete((rp, sp));
      };
      await Isolate.spawn(_startIsolateWorker, (initPort.sendPort, config));
      final (rp, sp) = await connection.future;
      workers[workerId] = (rp, sp);
    }
    return ._(workers);
  }

  static void _startIsolateWorker(dynamic message) {
    final (sp, config) =
        message
            as (
              SendPort,
              ({
                int workerId,
                String serviceName,
                Duration logRate,
                LogLevel minLevel,
              }),
            );
    final rp = ReceivePort();
    _handleCommandsToIsolateWorker(rp, sp, config);
    sp.send(rp.sendPort);
  }

  static void _handleCommandsToIsolateWorker(
    ReceivePort rp,
    SendPort sp,
    WorkerConfig config,
  ) {
    List<LogEntry> logs = [];
    var (:workerId, :serviceName, :logRate, :minLevel) = config;
    final logHandler = (_) {
      final message = _generateMessage(serviceName);
      final LogEntry entry = (
        workerId: workerId,
        serviceName: serviceName,
        timestamp: DateTime.now(),
        logLevel: minLevel,
        message: message,
      );
      logs.add(entry);
      sp.send((MessageType.logEntry, workerId, entry));
    };
    var timer = Timer.periodic(logRate, logHandler);

    rp.listen((message) {
      switch (message) {
        case (Command.pause) when timer.isActive:
          timer.cancel();
          sp.send((MessageType.statusUpdate, workerId, 'PAUSED'));
        case (Command.resume) when !timer.isActive:
          timer = Timer.periodic(logRate, logHandler);
          sp.send((MessageType.statusUpdate, workerId, 'RESUMED'));
        case (Command.requestStats):
          sp.send((
            MessageType.statusReport,
            workerId,
            logs.fold(
              <LogLevel, int>{},
              (prev, currLog) => {
                ...prev,
                currLog.logLevel: (prev[currLog.logLevel] ?? 0) + 1,
              },
            ),
          ));
        case (Command.shutdown):
          if (timer.isActive) timer.cancel();
          sp.send((MessageType.statusUpdate, workerId, 'CLOSED'));
          rp.close();
      }
    });
  }

  static String _generateMessage(String serviceName) {
    switch (serviceName) {
      case 'auth-service':
        return _dummy_auth_service_messages.randomChoice();
      case 'api-gateway':
        return _dummy_api_service_messages.randomChoice();
      case 'database':
        return _dummy_database_service_messages.randomChoice();
      case 'cache-service':
        return _dummy_cache_service_messages.randomChoice();
      default:
        return _unknown_service_messages.randomChoice();
    }
  }
}
