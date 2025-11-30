# NAME

Test::Which - Skip tests if external programs are missing from PATH (with version checks)

# VERSION

Version 0.04

# SYNOPSIS

    use Test::Which 'ffmpeg' => '>=6.0', 'convert' => '>=7.1';

    # At runtime in a subtest or test body
    use Test::Which qw(which_ok);

    subtest 'needs ffmpeg' => sub {
            which_ok 'ffmpeg' => '>=6.0' or return;
            ... # tests that use ffmpeg
    };

# DESCRIPTION

`Test::Which` mirrors [Test::Needs](https://metacpan.org/pod/Test%3A%3ANeeds) but checks for executables in PATH.
It can also check version constraints using a built-in heuristic that tries
common version flags (--version, -version, -v, -V) and extracts version numbers
from the output.

If a version is requested but cannot be determined, the requirement fails.

Key features:

- Compile-time and runtime checking of program availability
- Version comparison with standard operators (>=, >, <, <=, ==, !=)
- Regular expression matching for version strings
- Custom version flag support for non-standard programs
- Custom version extraction for unusual output formats
- Caching to avoid repeated program execution
- Cross-platform support (Unix, Linux, macOS, Windows)

# EXAMPLES

## Basic Usage

Check for program availability without version constraints:

    use Test::Which qw(which_ok);

    which_ok 'perl', 'ffmpeg', 'convert';

## Version Constraints

Check programs with minimum version requirements:

    # String constraints with comparison operators
    which_ok 'perl' => '>=5.10';
    which_ok 'ffmpeg' => '>=4.0', 'convert' => '>=7.1';

    # Exact version match
    which_ok 'node' => '==18.0.0';

    # Version range
    which_ok 'python' => '>=3.8', 'python' => '<4.0';

## Hashref Syntax

Use hashrefs for more complex constraints:

    # String version in hashref
    which_ok 'perl', { version => '>=5.10' };

    # Regex matching
    which_ok 'perl', { version => qr/5\.\d+/ };
    which_ok 'ffmpeg', { version => qr/^[4-6]\./ };

## Custom Version Flags

Some programs use non-standard flags to display version information:

    # Java uses -version (single dash)
    which_ok 'java', {
        version => '>=11',
        version_flag => '-version'
    };

    # Try multiple flags in order
    which_ok 'myprogram', {
        version => '>=2.0',
        version_flag => ['--show-version', '-version', '--ver']
    };

    # Program prints version without any flag
    which_ok 'sometool', {
        version => '>=1.0',
        version_flag => ''
    };

    # Windows-specific flag
    which_ok 'cmd', {
        version => qr/\d+/,
        version_flag => '/?'
    } if $^O eq 'MSWin32';

If `version_flag` is not specified, the module tries these flags in order:
`--version`, `-version`, `-v`, `-V` (and `/?`, `-?` on Windows)

## Custom Version Extraction

For programs with unusual version output formats:

    which_ok 'myprogram', {
        version => '>=1.0',
        extractor => sub {
            my $output = shift;
            return $1 if $output =~ /Build (\d+\.\d+)/;
            return undef;
        }
    };

The extractor receives the program's output and should return the version
string or undef if no version could be found.

## Mixed Usage

Combine different constraint types:

    which_ok
        'perl' => '>=5.10',           # String constraint
        'ffmpeg',                      # No constraint
        'convert', { version => qr/^7\./ };  # Regex constraint

## Compile-Time Checking

Skip entire test files if requirements aren't met:

    use Test::Which 'ffmpeg' => '>=6.0', 'convert' => '>=7.1';

    # Test file is skipped if either program is missing or version too old
    # No tests below this line will run if requirements aren't met

## Runtime Checking in Subtests

Check requirements for individual subtests:

    use Test::Which qw(which_ok);

    subtest 'video conversion' => sub {
        which_ok 'ffmpeg' => '>=4.0' or return;
        # ... tests using ffmpeg
    };

    subtest 'image processing' => sub {
        which_ok 'convert' => '>=7.0' or return;
        # ... tests using ImageMagick
    };

## Absolute Paths

You can specify absolute paths instead of searching PATH:

    which_ok '/usr/local/bin/myprogram' => '>=1.0';

The program must be executable.

# VERSION DETECTION

The module attempts to detect version numbers using these strategies in order:

- 1. Look for version near the word "version" (case-insensitive)

    Matches patterns like: `ffmpeg version 4.2.7`, `Version: 2.1.0`

- 2. Extract dotted version from first line of output

    Common for programs that print version info prominently

- 3. Find any dotted version number in output

    Fallback for less standard formats

- 4. Look for single number near "version"

    For programs that use simple integer versioning

- 5. Use any standalone number found

    Last resort - least reliable

# VERSION COMPARISON

Version comparison uses Perl's [version](https://metacpan.org/pod/version) module. Versions are normalized
to have the same number of components before comparison to avoid
`version.pm`'s parsing quirks.

For example:
  - `2020.10` becomes `2020.10.0`
  - `2020.10.15` stays `2020.10.15`
  - Then they're compared correctly

Supported operators: `>=`, `>`, `<=`, `<`, `=`, `!=`

# CACHING

Version detection results are cached to avoid repeated program execution.
Each unique combination of program path and version flags creates a separate
cache entry.

Cache benefits:
\- Faster repeated checks in test suites
\- Reduced system load
\- Works across multiple test files in the same process

The cache persists for the lifetime of the Perl process.

# VERBOSE OUTPUT

Set environment variables to see detected versions:

    TEST_WHICH_VERBOSE=1 prove -v t/mytest.t
    TEST_VERBOSE=1 perl t/mytest.t
    prove -v t/mytest.t  # HARNESS_IS_VERBOSE is set automatically

Output includes the detected version for each checked program:

    # perl: version 5.38.0
    # ffmpeg: version 6.1.1

# PLATFORM SUPPORT

- **Unix/Linux/macOS**: Full support for all features
- **Windows**: Basic functionality supported. Complex shell features
(STDERR redirection, empty flags) may have limitations.

# DIAGNOSTICS

Common error messages:

- `Missing required program 'foo'`

    The program 'foo' could not be found in PATH.

- `Version issue for foo: no version detected`

    The program exists but the module couldn't extract a version number from
    its output. Try specifying a custom `version_flag` or `extractor`.

- `Version issue for foo: found 1.0 but need `=2.0>

    The program's version doesn't meet the constraint.

- `Version issue for foo: found version 1.0 but doesn't match pattern`

    For regex constraints, the detected version didn't match the pattern.

- `hashref constraint must contain 'version' key`

    When using hashref syntax, you must include a `version` key.

- `invalid constraint 'foo'`

    The version constraint string couldn't be parsed. Use formats like
    `'`=1.2.3'>, `'`2.0'>, or `'1.5'`.

# FUNCTIONS/METHODS

## which\_ok @programs\_or\_pairs

Checks the named programs (with optional version constraints).
If any requirement is not met, the current test or subtest is skipped
via [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder).

Returns true if all requirements are met, false otherwise.

# SUPPORT

This module is provided as-is without any warranty.

# SEE ALSO

[Test::Needs](https://metacpan.org/pod/Test%3A%3ANeeds) - Similar module for checking Perl module availability

[File::Which](https://metacpan.org/pod/File%3A%3AWhich) - Used internally to locate programs

[version](https://metacpan.org/pod/version) - Used for version comparison

[Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) - Used for test integration

# LIMITATIONS

- Version detection is heuristic-based and may fail for programs with
unusual output formats. Use custom `version_flag` or `extractor` for such cases.
- No built-in timeout for program execution. Hanging programs will hang tests.
- Cache persists for process lifetime - updated programs won't be re-detected
without restarting the test process.
- Requires programs to be in PATH or specified with absolute paths.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
