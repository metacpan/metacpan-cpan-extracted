# NAME

Test::Which - Skip tests if external programs are missing from PATH (with version checks)

# VERSION

Version 0.03

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
It can also check simple version constraints using a built-in heuristic (tries --version, -version, -v, -V and extracts a dotted-number).
If a version is requested but cannot be determined, the requirement fails.

## EXAMPLES

    # String constraints
    which_ok 'perl' => '>=5.10';
    which_ok 'ffmpeg' => '>=4.0', 'convert' => '7.1';

    # Regex constraints
    which_ok 'perl', { version => qr/5\.\d+/ };

    # Mixed
    which_ok 'perl' => '>=5.10', 'ffmpeg', { version => qr/^[4-6]\./ };

    # Just program names
    which_ok 'perl', 'ffmpeg', 'convert';

    # String in hashref (for consistency)
    which_ok 'perl', { version => '>=5.10' };

# FUNCTIONS

## which\_ok @programs\_or\_pairs

Checks the named programs (with optional version constraints).
If any requirement is not met the current test or subtest is skipped via [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder).

# SUPPORT

This module is provided as-is without any warranty.

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
