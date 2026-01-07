# Real-Time Multi-Worker Log Aggregator System

## Objective

Build a bidirectional communication system with **MULTIPLE worker isolates** that generate logs at different rates, while the main isolate aggregates logs and can send commands to control worker behavior in real-time.

## Workflow

### 1. Main spawns multiple worker isolates (e.g., 3-5 workers)

-   Each worker has a unique ID and configuration (log rate, service name)

### 2. Workers autonomously generate logs

-   Each worker generates log entries at its configured rate
-   Log entries include: timestamp, worker ID, log level, service name, message
-   Workers send logs to main isolate in real-time
-   Workers track their own statistics (total logs, logs by level)

### 3. Main aggregates and displays logs

-   Receives logs from all workers
-   Displays logs in a unified stream
-   Maintains aggregate statistics across all workers

### 4. Bidirectional control commands

**Main → Worker Commands:**

-   `PAUSE` - Stop generating logs
-   `RESUME` - Resume generating logs
-   `CHANGE_LEVEL` - Change minimum log level
-   `REQUEST_STATS` - Request worker statistics
-   `SHUTDOWN` - Clean shutdown

**Worker → Main Messages:**

-   `LOG_ENTRY` - Individual log entry
-   `STATS_REPORT` - Statistics response
-   `STATUS_UPDATE` - Worker state change notification

## Communication Pattern

```dart
// Main → Worker
(Command.pause, workerId)
(Command.resume, workerId)
(Command.requestStats, workerId)
(Command.changeLevel, workerId, LogLevel.error)
(Command.shutdown, workerId)

// Worker → Main
(MessageType.logEntry, workerId, LogEntry(...))
(MessageType.statsReport, workerId, WorkerStats(...))
(MessageType.statusUpdate, workerId, 'PAUSED')
```

## Features to Demonstrate

-   ✅ **Multiple isolate communication** - Managing 3-5 workers simultaneously
-   ✅ **Bidirectional messaging** - Commands and event streaming
-   ✅ **Real-time data streaming** - Continuous log generation
-   ✅ **Dynamic worker control** - Pause, resume, configure on-the-fly
-   ✅ **State synchronization** - Workers maintain and report state
-   ✅ **Statistics aggregation** - Collecting data from multiple sources
-   ✅ **Graceful shutdown** - Coordinating shutdown across multiple isolates

## Resources

### Log Levels

```dart
enum LogLevel {
  debug,
  info,
  warn,
  error,
  fatal,
}
```

### Worker Configurations

```dart
final workerConfigs = [
  WorkerConfig(
    id: 1,
    serviceName: 'auth-service',
    logRate: Duration(milliseconds: 500),
    minLevel: LogLevel.debug,
  ),
  WorkerConfig(
    id: 2,
    serviceName: 'api-gateway',
    logRate: Duration(milliseconds: 300),
    minLevel: LogLevel.info,
  ),
  WorkerConfig(
    id: 3,
    serviceName: 'database',
    logRate: Duration(milliseconds: 800),
    minLevel: LogLevel.warn,
  ),
  WorkerConfig(
    id: 4,
    serviceName: 'cache-service',
    logRate: Duration(milliseconds: 600),
    minLevel: LogLevel.info,
  ),
];
```

### Sample Log Messages by Service

```dart
const logMessages = {
  'auth-service': [
    'User authentication successful',
    'Token generated',
    'Invalid token signature',
    'Session expired',
    'Password reset requested',
  ],
  'api-gateway': [
    'Incoming request: GET /api/users',
    'Route matched',
    'Response sent: 200 OK',
    'Rate limit exceeded',
    'Invalid API key',
  ],
  'database': [
    'Connection pool at 80% capacity',
    'Slow query detected',
    'Transaction committed',
    'Deadlock detected',
    'Connection timeout',
  ],
  'cache-service': [
    'Cache hit rate: 94.2%',
    'Cache miss - fetching from DB',
    'Cache eviction triggered',
    'Memory usage: 75%',
    'Cache cleared',
  ],
};
```

## Expected Output Format

```
[14:23:45.123] [W1] [auth-service]  [INFO]  User login attempt
[14:23:45.324] [W2] [api-gateway]   [DEBUG] Route matched: /api/users
[14:23:45.456] [W1] [auth-service]  [INFO]  Token generated
[14:23:45.789] [W3] [database]      [WARN]  Slow query detected: 245ms
[14:23:46.012] [W4] [cache-service] [INFO]  Cache hit rate: 94.2%

--- Command Sent: PAUSE Worker-2 ---
[W2] Status: PAUSED

--- Command Sent: REQUEST_STATS Worker-1 ---
[W1] Stats: {total: 45, debug: 10, info: 30, warn: 4, error: 1}

--- Command Sent: RESUME Worker-2 ---
[W2] Status: RUNNING

=== AGGREGATE STATISTICS ===
Total Logs: 178
By Level: DEBUG: 42, INFO: 98, WARN: 25, ERROR: 13
Active Workers: 4/4
Uptime: 30.5s
```

## Example Workflow in main()

```dart
void main(List<String> args) async {
  // 1. Spawn all workers with their configurations

  // 2. Let them run and generate logs for 3 seconds

  // 3. Send PAUSE command to worker 2

  // 4. Wait 2 seconds

  // 5. Send REQUEST_STATS to all workers

  // 6. Wait 1 second

  // 7. Send RESUME to worker 2

  // 8. Let run for 5 more seconds

  // 9. Display aggregate statistics

  // 10. Send SHUTDOWN to all workers
}
```

## Running the Project

```bash
# Run the log aggregator
dart main.dart

# Run for specific duration
timeout 15 dart main.dart
```

## Data Structures to Implement

```dart
class WorkerConfig {
  final int id;
  final String serviceName;
  final Duration logRate;
  final LogLevel minLevel;
}

class LogEntry {
  final DateTime timestamp;
  final int workerId;
  final String serviceName;
  final LogLevel level;
  final String message;
}

class WorkerStats {
  final int workerId;
  final int totalLogs;
  final Map<LogLevel, int> logsByLevel;
  final Duration uptime;
  final String status; // 'RUNNING', 'PAUSED'
}
```

## Implementation Tips

1. **Worker Identification**: Use worker ID to track which worker sent each message
2. **Timer-based Log Generation**: Use `Timer.periodic` in worker isolates
3. **Random Messages**: Pick random messages from the `logMessages` map
4. **State Management**: Workers should maintain their own state (running/paused)
5. **Statistics Tracking**: Increment counters for each log level
6. **Graceful Pause**: Cancel timer when paused, recreate when resumed
7. **Command Routing**: Main needs to route commands to specific workers

Good luck! 🚀
