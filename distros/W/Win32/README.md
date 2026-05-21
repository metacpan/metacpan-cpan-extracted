# Win32

[![CI](https://github.com/perl-libwin32/win32/actions/workflows/test.yml/badge.svg)](https://github.com/perl-libwin32/win32/actions/workflows/test.yml)
[![CPAN version](https://img.shields.io/cpan/v/Win32)](https://metacpan.org/pod/Win32)

Interfaces to some Win32 API functions.

The `Win32` module bundles small Perl wrappers around the Win32 API —
process and user information, paths, shortcuts, registry keys, system
metrics, and more. Most originated in the "Perl for Win32" port from
ActiveWare; Perl later split them out of the core interpreter into a
separate distribution to keep the core lean.

The module is dual-life: it has shipped with core Perl since 5.8.4,
but the CPAN release is the upgrade path for users on Perls that
bundle an older copy.

## Documentation

Full reference documentation is on MetaCPAN: <https://metacpan.org/pod/Win32>

## Installation

    cpanm Win32

## Bug tracker

<https://github.com/perl-libwin32/win32/issues>

## License

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
