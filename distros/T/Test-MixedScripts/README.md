# NAME

Test::MixedScripts - test text for mixed and potentially confusable Unicode scripts

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use Test::MixedScripts qw( all_perl_files_scripts_ok file_scripts_ok );

all_perl_files_scripts_ok();

file_scripts_ok( 'assets/site.js' );
```

# DESCRIPTION

This is a module to test that Perl code and other text files do not have potentially malicious or confusing Unicode
combinations.

# EXPORTS

## file\_scripts\_ok

```
file_scripts_ok( $filepath, @scripts );
```

This tests that the text file at `$filepath` contains only characters in the specified `@scripts`.
If no scripts are given, it defaults to `Common` and `Latin` characters.

You can override the defaults by adding a list of Unicode scripts, for example

```
file_scripts_ok( $filepath, qw/ Common Latin Cyryllic / );
```

You can also pass options as a hash reference,

```perl
file_scripts_ok( $filepath, { scripts => [qw/ Common Latin Cyryllic /] } );
```

A safer alternative to overriding the default scripts for a file is to specify an exception on each line using a special
comment:

```
"English bŭlgarski" ## Test::MixedScripts Latin,Cyrillic,Common
```

## all\_perl\_files\_scripts\_ok

```
all_perl_files_scripts_ok();

all_perl_files_scripts_ok( \%options, @dirs );
```

This applies ["file\_scripts\_ok"](#file_scripts_ok) to all of the Perl scripts in `@dirs`, or the current directory if they are omitted.

# SEE ALSO

[Test::PureASCII](https://metacpan.org/pod/Test%3A%3APureASCII) tests that only ASCII characters are used.

[Unicode Confusables](https://util.unicode.org/UnicodeJsps/confusables.jsp)

[Detecting malicious Unicode](https://daniel.haxx.se/blog/2025/05/16/detecting-malicious-unicode/)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Test-MixedScripts](https://github.com/robrwo/perl-Test-MixedScripts)
and may be cloned from [git://github.com/robrwo/perl-Test-MixedScripts.git](git://github.com/robrwo/perl-Test-MixedScripts.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Test-MixedScripts/issues](https://github.com/robrwo/perl-Test-MixedScripts/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The file traversing code used in ["all\_perl\_files\_scripts\_ok"](#all_perl_files_scripts_ok) is based on code from [Test::EOL](https://metacpan.org/pod/Test%3A%3AEOL) by Tomas Doran
<bobtfish@bobtfish.net> and others.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
