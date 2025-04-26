
# gerr - Eureka Error System v1.1.7

## Overview

`gerr` is a Perl module designed to enhance error and debugging management in Perl scripts by providing custom error messages, stack traces, and handlers for warnings and fatal errors. It offers a consistent approach to handle errors and warnings, making debugging more manageable and informative.

## Features

- **Custom Error Messages**: Format error messages with additional context.
- **Stack Traces**: Capture and format stack traces for better debugging.
- **Custom Warning and Fatal Error Handlers**: Replace default Perl handlers for warnings and fatal errors with custom implementations.
- **Flexible Configuration**: Customize error types, message sizes, and trace depths.

## Installation

You can install `gerr` from CPAN or from the GitHub repository.

### Install from CPAN

You can install `gerr` from CPAN using the following command:

```sh
cpanm gerr
```

Alternatively, you can use `cpan` directly:

```sh
cpan gerr
```

### Install from GitHub

To install `gerr` from GitHub, follow these steps:

1. Clone the repository:

    ```sh
    git clone https://github.com/DomeroSoftware/gerr.git
    ```

2. Change directory to the cloned repository:

    ```sh
    cd gerr
    ```

3. Build and install the module:

    ```sh
    perl Makefile.PL
    make
    make test
    make install
    ```

## Usage

To use the `gerr` module in your Perl script, include it using one of the following methods:

### Standard Usage

   ```perl
   use gerr qw(error Warn Die);

   # Output the error message
   Warn( error("Something went wrong", "type=Warning", "trace=3", "return=1") );
   Die( error("Something went REALY wrong", "type=Fatal Error", "trace=3", "return=1") );
   ```

### Using `:control` to Override `warn` and `die`

   ```perl
   use gerr qw(:control);

   # Generate a warning
   warn "Something went wrong";

   # Generate a fatal error
   die "Something went REALY wrong";
   ```

## Functions

### `error(@messages)`

Generates a formatted error message. Options include `return`, `type`, `size`, and `trace`.

### `trace($depth)`

Generates a stack trace with the given depth. The default depth is 1.

### `Warn($message)`

Custom implementation for warnings. Formats the message and invokes the warning signal handler if defined.

### `Die($message)`

Custom implementation for fatal errors. Formats the message and invokes the die signal handler if defined, and exits the program if not in an eval block.

## Custom Error Handling

### `Warn`

Formats the warning message, includes the call location, and either invokes a custom warning handler if defined or prints the message to STDERR.

### `Die`

Formats the fatal error message, includes the call location, and either invokes a custom die handler if defined or prints the message to STDERR and exits the program if not in an eval block.

## Export

By default, only the `error` function is exported. To use custom warning and die handlers, use the `:control` tag.

## Advanced Usage

The `:control` tag enables overriding Perl's built-in `warn` and `die` functions with `Warn` and `Die` methods from `gerr`. This ensures consistent formatting for warnings and errors across your application, even when other modules or packages are used.

## Contributing

If you would like to contribute to `gerr`, please visit the [GitHub repository](https://github.com/DomeroSoftware/gerr) and submit issues, suggestions, or pull requests.

## License

Copyright (C) 2020 Domero Software. All rights reserved.

This module is released under the same terms as Perl itself.

## Contact

For further information, updates, or to report issues, please visit the [GitHub repository](https://github.com/DomeroSoftware/gerr).
