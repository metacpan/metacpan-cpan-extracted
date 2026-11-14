# NAME

mayhaps - call methods conditionally for any class or object

# SYNOPSIS

```perl
use mayhaps;

$obj->mayhaps::frobnicate( $bool, @args );
```

is equivalent to

```
($bool) ? $obj->frobnicate(@args) : $obj;
```

# DESCRIPTION

This module allows you to call methods conditionally.

Methods are prefixed with `mehaps::`, and the first argument is a conditional.
When it is true, the method is called with the remaining arguments.
Otherwise it returns the object.

This is useful for chained methods, for example:

```perl
my $rs = $schema->resultset('Books')
          ->with_authors
          ->with_publishers
          ->mayhaps::with_sales_stats( $is_internal );
```

## What does "mayhaps" mean?

It is an archaic English synonym for "maybe".
There is already a module called [maybe](https://metacpan.org/pod/maybe) with a different function.

# RECENT CHANGES

Changes for version v0.1.2 (2026-11-13)

- Documentation
    - Improved synopsis.
    - Added a security considerations section.
- Tests
    - Added more test cases.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan mayhaps
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SECURITY CONSIDERATIONS

There is no validation of the object or the calling method.

# SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.14 or later.
Future releases may only support Perl versions released in the last ten years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-mayhaps/issues](https://github.com/robrwo/perl-mayhaps/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-mayhaps](https://github.com/robrwo/perl-mayhaps)
and may be cloned from [https://github.com/robrwo/perl-mayhaps.git](https://github.com/robrwo/perl-mayhaps.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
