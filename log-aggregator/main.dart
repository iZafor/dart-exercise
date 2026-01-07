import 'worker.dart';

final workerConfigs = <WorkerConfig>[
  (
    workerId: 1,
    serviceName: 'auth-service',
    logRate: Duration(milliseconds: 500),
    minLevel: LogLevel.debug,
  ),
  (
    workerId: 2,
    serviceName: 'api-gateway',
    logRate: Duration(milliseconds: 300),
    minLevel: LogLevel.info,
  ),
  (
    workerId: 3,
    serviceName: 'database',
    logRate: Duration(milliseconds: 800),
    minLevel: LogLevel.warn,
  ),
  (
    workerId: 4,
    serviceName: 'cache-service',
    logRate: Duration(milliseconds: 600),
    minLevel: LogLevel.info,
  ),
];

void main(List<String> args) async {
  final worker = await Worker.spawnWorkers(workerConfigs);
  await worker.simulateMultipleWorkers();
}
