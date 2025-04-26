
# glog and glog::logger - Pure Perl Logging

[![CPAN Version](https://badge.fury.io/pl/glog.svg)](https://metacpan.org/pod/glog)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Introduction

`glog::logger` is a high-performance, Pure Perl object-oriented logging module designed for the G collection, providing robust logging capabilities with support for multiple log levels (ERROR, WARN, INFO, DEBUG), timestamped output, and flexible output destinations (STDERR or file). The `glog` module serves as a lightweight, functional proxy, offering a simple interface that delegates all operations to a global `glog::logger` instance.

These modules are built to be fast, reliable, and easy to integrate into both small scripts and large systems, maintaining the quality standards.

## Features

- **Pure Perl**: No external dependencies beyond standard Perl modules.
- **Flexible Logging**: Supports ERROR (1), WARN (2), INFO (3), and DEBUG (5) levels.
- **Timestamped Output**: High-resolution timestamps using `Time::HiRes`.
- **Output Options**: Log to STDERR or a file, with seamless switching.
- **Simple Interface**: `glog` provides a drop-in functional API (`LogInfo`, `LogWarn`, etc.).
- **Object-Oriented Core**: `glog::logger` encapsulates all logic, allowing multiple logger instances.
- **Standards Compliant**: Consistent with the G collection's design principles.

## Installation

To install `glog` from CPAN, use:

```bash
cpan glog
```

Or manually:

```bash
git clone https://github.com/DomeroSoftware/glog.git
cd glog
perl Makefile.PL
make
make test
make install
```

### Dependencies

- Core Perl modules: `Exporter`, `strict`, `warnings`, `Time::HiRes`, `POSIX`
- Testing: `Test::More` (>= 0.88)
- Required: `gerr` (for error handling in `glog::logger`, available on CPAN)

## Usage

### Using `glog` for Simple Logging

The `glog` module provides a functional interface for quick logging:

```perl
use glog;

# Set log level
LogLevel(5); # Enable debug logging

# Log messages
LogInfo("Application started");
LogDebug("Debug details: x=42");
LogWarn("Warning: low disk space");
LogErr("Error: cannot open file");
LogDie("Fatal error!"); # Logs and dies

# Formatted logging
LogF(3, "User %s logged in at %d", "alice", time);

# Log to file
LogFile("app.log");
LogInfo("Logging to file");
LogFile(undef); # Revert to STDERR
```

### Using `glog::logger` for Advanced Logging

For more control, use the `glog::logger` module directly:

```perl
use glog::logger;

# Create a logger instance
my $logger = glog::logger->new;

# Set log level
$logger->LogLevel(3);

# Log messages
$logger->LogInfo("Starting process");
$logger->LogFormat(3, "Processing %d items", 42);

# Log to file
$logger->LogFile("process.log");
$logger->LogWarn("Potential issue detected");
$logger->LogFile(undef); # Back to STDERR
```

## Log Levels

- **1: ERROR** - Critical errors
- **2: WARN** - Warnings
- **3: INFO** - Informational messages
- **5: DEBUG** - Detailed debugging information

Messages are only logged if their level is less than or equal to the current log level.

## Output Format

Log messages follow this format:

```text
[YYYY-MM-DD HH:MM:SS.mmm] LEVEL message
```

Example:

```text
[2025-04-25 20:15:23.456] INFO Application started
```

## Performance

`glog` and `glog::logger` are optimized for minimal overhead:

- Early level checks to skip unnecessary processing.
- Efficient timestamp generation with `Time::HiRes`.
- Lightweight proxy in `glog` with direct delegation to `glog::logger`.
- Reusable file handles and configuration state.

Benchmarks in the test suite demonstrate low-latency logging even for high-frequency calls.

## Testing

The distribution includes comprehensive tests in the `t/` directory, covering:

- All log levels and message types.
- Formatted logging with `LogF`.
- File-based logging with `LogFile`.
- Error handling and `LogDie` behavior.

Run tests with:

```bash
make test
```

## Documentation

Detailed documentation is available in the POD sections of each module:

- `perldoc glog`
- `perldoc glog::logger`

## Limitations

- No built-in log rotation for file-based logging.
- No native threading support.

## Contributing

Contributions are welcome! Please submit issues or pull requests at:

[https://github.com/DomeroSoftware/glog](https://github.com/DomeroSoftware/glog)

See `CONTRIBUTING.md` (if available) for guidelines.

## License

This module is released under the [MIT License](LICENSE).

## Author

OnEhIppY <domerosoftware@gmail.com>, Domero Software

## Copyright

Copyright © 2025 OnEhIppY, Domero Software