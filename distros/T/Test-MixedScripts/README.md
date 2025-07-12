# NAME

Test::MixedScripts - test text for mixed and potentially confusable Unicode scripts

# VERSION

version v0.6.2

# SYNOPSIS

```perl
use Test::V0;
use Test::MixedScripts v0.3.0 qw( all_perl_files_scripts_ok file_scripts_ok );

all_perl_files_scripts_ok();

file_scripts_ok( 'assets/site.js' );

done_testing;
```

# DESCRIPTION

This is a module to test that Perl code and other text files do not have potentially malicious or confusing Unicode
combinations.

For example, the text for the domain names "оnе.example.com" and "one.example.com" look indistinguishable in many fonts,
but the first one has Cyrillic letters.  If your software interacted with a service on the second domain, then someone
can operate a service on the first domain and attempt to fool developers into using their domain instead.

This might be through a malicious patch submission, or even text from an email or web page that they have convinced a
developer to copy and paste into their code.

# EXPORTS

## file\_scripts\_ok

```
file_scripts_ok( $filepath, @scripts );
```

This tests that the text file at `$filepath` contains only characters in the specified `@scripts`.
If no scripts are given, it defaults to `Common` and `Latin` characters.

You can override the defaults by adding a list of Unicode scripts, for example

```
file_scripts_ok( $filepath, qw/ Common Latin Cyrillic / );
```

You can also pass options as a hash reference,

```perl
file_scripts_ok( $filepath, { scripts => [qw/ Common Latin Cyrillic /] } );
```

A safer alternative to overriding the default scripts for a file is to specify an exception on each line using a special
comment:

```
"English bŭlgarski" ## Test::MixedScripts Latin,Cyrillic,Common
```

You can also override the default scripts with a special POD directive, which will change the scripts for all lines
(code or POD) that follow:

```
=for Test::MixedScripts Latin,Cyrillic,Common
```

You can reset to the default scripts using:

```
=for Test::MixedScripts default
```

You can escape the individual characters in strings and regular expressions using hex codes, for example,

```
say qq{The Cyryllic "\x{043e}" looks like an "o".};
```

and in POD using the `E` formatting code. For example,

```
=pod

The Cyryllic "E<0x043e>" looks like an "o".

=cut
```

See [perlpod](https://metacpan.org/pod/perlpod) for more information.

When tests fail, the diagnostic message will indicate the unexpected script and where the character was in the file:

```
Unexpected Cyrillic character CYRILLIC SMALL LETTER ER on line 286 character 45 in lib/Foo/Bar.pm
```

You can also specify "ASCII" as a special script name for only 7-bit ASCII characters:

```
file_scripts_ok( $filepath, qw/ ASCII / );
```

Note that "ASCII" is available in version v0.6.0 or later.

## all\_perl\_files\_scripts\_ok

```
all_perl_files_scripts_ok();

all_perl_files_scripts_ok( \%options );
```

This applies ["file\_scripts\_ok"](#file_scripts_ok) to all of the Perl scripts in the current directory, based the distribution
[MANIFEST](https://metacpan.org/pod/ExtUtils%3A%3AManifest).

# KNOWN ISSUES

## Unicode and Perl Versions

Some scripts were added to later versions of Unicode, and supported by later versions of Perl.  This means that you
cannot run tests for some scripts on older versions of Perl.
See [Unicode Supported Scripts](https://www.unicode.org/standard/supported.html) for a list of scripts supported
by Unicode versions.

## Pod::Weaver

The `=for` directive is not consistently copied relative to the sections that occur in by [Pod::Weaver](https://metacpan.org/pod/Pod%3A%3AWeaver).

## Other Limitations

This will not identify confusable characters from the same scripts.

# SEE ALSO

[Test::PureASCII](https://metacpan.org/pod/Test%3A%3APureASCII) tests that only ASCII characters are used.

[Unicode::Confuse](https://metacpan.org/pod/Unicode%3A%3AConfuse) identifies [Unicode Confusables](https://util.unicode.org/UnicodeJsps/confusables.jsp).

[Unicode::Security](https://metacpan.org/pod/Unicode%3A%3ASecurity) implements several security mechanisms described in
[Unicode Security Mechanisms](https://www.unicode.org/reports/tr39/).

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

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
