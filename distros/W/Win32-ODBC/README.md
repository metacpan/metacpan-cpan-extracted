# Win32::ODBC

[![CI](https://github.com/perl-libwin32/win32-odbc/actions/workflows/test.yml/badge.svg)](https://github.com/perl-libwin32/win32-odbc/actions/workflows/test.yml)
[![CPAN version](https://img.shields.io/cpan/v/Win32-ODBC)](https://metacpan.org/pod/Win32::ODBC)

ODBC Extension for Win32.

This module wraps the Windows ODBC API. A script opens a connection to
any data source that has an ODBC driver, by DSN or by connection string,
sends SQL with `Sql()`, and reads the results back with `FetchRow()`.

Dave Roth released the original in 1996, building on Dan DeMaggio's
ODBC code. It shipped in the `libwin32` bundle until Jan Dubois split it
out for separate CPAN release in 2008. The perl-libwin32 organization
now maintains it. `README.TXT` is Dave Roth's original manual, but its
build and install steps are obsolete.

## Documentation

Full reference documentation is on MetaCPAN: <https://metacpan.org/pod/Win32::ODBC>

## Installation

    cpanm Win32::ODBC

## Bug tracker

<https://github.com/perl-libwin32/win32-odbc/issues>

## License

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
