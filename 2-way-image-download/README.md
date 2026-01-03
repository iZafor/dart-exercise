# Concurrent 2-Way Communication Image Processing System

## Objective

Build a bidirectional communication system between main isolate and worker isolate where the worker processes image URLs but needs to communicate back to main for validation and configuration.

## Workflow

1. **Main sends a batch of image URLs to worker for processing**

2. **Worker processes each URL:**

    - a. Sends a validation request back to main asking if URL is allowed
    - b. Main validates URL against whitelist and responds
    - c. If valid, worker downloads image and displays progress
    - d. Worker sends progress updates back to main (e.g., "Processing 3/10")
    - e. Worker sends final result (metadata) back to main

3. **Main aggregates all results and displays summary**

## 2-Way Communication Pattern

```
Main -> Worker: (Command.process, id, (url, total))
Worker -> Main: (Response.validate, url, current, total)
Main -> Worker: (Command.download, (url, isAllowed))
Worker -> Main: (Response.result, id, status)
Main -> Worker: (Command.shutdown)
```

### Message Flow

| Direction     | Message Type | Purpose                                  |
| ------------- | ------------ | ---------------------------------------- |
| Main → Worker | `process`    | Send URL to process                      |
| Worker → Main | `validate`   | Request URL validation + progress update |
| Main → Worker | `download`   | Send validation result                   |
| Worker → Main | `result`     | Send processing result                   |
| Main → Worker | `shutdown`   | Clean shutdown signal                    |

## Features Demonstrated

-   ✅ **Bidirectional SendPort communication** - Messages flow both directions
-   ✅ **Worker requesting data from main isolate** - Worker asks main for validation
-   ✅ **Main responding to worker requests** - Main validates and responds
-   ✅ **Progress reporting during long operations** - Real-time progress updates
-   ✅ **Error handling in both directions** - Errors caught and reported
-   ✅ **Clean shutdown protocol** - Proper resource cleanup

## Resources

### URLs to Process

```dart
const urls = [
  'https://picsum.photos/200/300',
  'https://picsum.photos/400/400',
  'https://example.com/bad-image.jpg',      // This will be rejected
  'https://picsum.photos/800/600',
  'https://picsum.photos/1024/768',
  'https://images.pexels.com/photos/267961/pexels-photo-267961.jpeg',
  'https://images.pexels.com/photos/746386/pexels-photo-746386.jpeg',
];
```

### Allowed Domains for Validation

```dart
const allowedDomains = [
  'picsum.photos',
  'images.unsplash.com',
  'images.pexels.com',
];
```

## Running the Project

```bash
# Run the main program
dart main.dart

# Clean up downloaded images
rm -rf ./images/
```

## Project Structure

```
.
├── main.dart         # Entry point with task configuration
├── worker.dart       # Worker isolate implementation
├── extension.dart    # String and Int extensions
├── README.md         # This file
└── .gitignore        # Git ignore rules
```

## Implementation Details

### Main Isolate Responsibilities

-   Spawns worker isolate
-   Sends URLs for processing
-   Validates URLs when requested by worker
-   Receives progress updates
-   Receives results and errors
-   Manages shutdown

### Worker Isolate Responsibilities

-   Receives URLs from main
-   Requests validation for each URL
-   Downloads images if validated
-   Reports progress after each URL
-   Sends results/errors back to main
-   Handles shutdown command

### Custom URI Parser

The project includes a custom URI parser (`toUri()` extension) that manually parses URLs to demonstrate string manipulation and URI structure understanding.

### Download Progress Indicator

Images are downloaded with a visual progress bar showing:

-   Download progress (█ characters)
-   Current size / Total size
-   Real-time updates during download

## Key Learning Points

1. **Isolate Communication** - Using `SendPort` and `ReceivePort` for bidirectional messaging
2. **Pattern Matching** - Dart 3 pattern matching for message handling
3. **Async/Await** - Proper async handling in isolate contexts
4. **Completer Usage** - Managing async request/response patterns
5. **Error Handling** - Graceful error handling across isolate boundaries
