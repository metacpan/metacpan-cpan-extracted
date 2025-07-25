# NAME

Test2::Util::DistFiles - Gather a list of files in a distribution

# VERSION

version v0.2.1

# SYNOPSIS

```perl
use Test2::V0;
use Test2::Util::DistFiles qw( manifest_files is_perl_file );

my @perl = manifest_files( \&is_perl_file);
```

# DESCRIPTION

This is a utility module that gathers lists files in a distribution, intended for author, or release tests for
developers.

# EXPORTS

## manifest\_files

```perl
my @files = manifest_files(); # use default filter

my @files = manifest_files( \%options, \&filter );

my @perl  = manifest_files( \&is_perl_file );
```

This returns a list of files from the `MANIFEST`, filtered by an optional function.

If there is no manifest, then it will use [ExtUtils::Manifest](https://metacpan.org/pod/ExtUtils%3A%3AManifest) to build a list of files that would be added to the
manifest.

The following options are supported:

## is\_perl\_file

This returns a list of Perl files in the distribution, excluding installation scaffolding like [Module::Install](https://metacpan.org/pod/Module%3A%3AInstall) files
in `inc`.

Note that it will include files like `Makefile.PL` or `Build.PL`.

- dir

    Search for files in this directory.

- use\_default

    Use the default filter to ignore local lib files, build files, version control files and temporary files.

    This is true by default.

# SEE ALSO

[Test::XTFiles](https://metacpan.org/pod/Test%3A%3AXTFiles)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Test2-Util-DistFiles](https://github.com/robrwo/perl-Test2-Util-DistFiles)
and may be cloned from [git://github.com/robrwo/perl-Test2-Util-DistFiles.git](git://github.com/robrwo/perl-Test2-Util-DistFiles.git)

See `CONTRIBUTING.md` for more information.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.14 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Test2-Util-DistFiles/issues](https://github.com/robrwo/perl-Test2-Util-DistFiles/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
