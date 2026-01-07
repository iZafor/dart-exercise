# Dart Basic Projects

A collection of Dart projects demonstrating core language features and concurrency patterns.

## Projects

### [2-way-image-download](2-way-image-download/)

A bidirectional isolate communication example that downloads images concurrently using Dart isolates. Demonstrates worker-main communication patterns with progress tracking and error handling.

**Key Features:**

-   Bidirectional isolate communication
-   Concurrent image downloading
-   Progress tracking and status updates
-   Error handling across isolate boundaries

### [log-aggregator](log-aggregator/)

A multi-worker log aggregation system demonstrating advanced isolate management and inter-process communication. Simulates distributed service logging with real-time aggregation.

**Key Features:**

-   Multi-isolate worker spawning and management
-   Command system (pause, resume, requestStats, shutdown)
-   Service-specific log generation (auth, API, database, cache)
-   Real-time log aggregation with configurable rates
-   Statistics tracking and reporting
-   Message passing between isolates

## Running the Projects

Each project can be run independently:

```bash
# 2-way-image-download
cd 2-way-image-download
dart run main.dart

# log-aggregator
cd log-aggregator
dart run main.dart
```

## Learning Focus

These projects showcase:

-   Dart isolate-based concurrency
-   Inter-isolate communication using SendPort/ReceivePort
-   Worker pattern implementation
-   Asynchronous programming with Future and Stream
-   Record types and pattern matching
