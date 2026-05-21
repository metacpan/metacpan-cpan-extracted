# Win32::Pipe

[![CI](https://github.com/perl-libwin32/win32-pipe/actions/workflows/test.yml/badge.svg)](https://github.com/perl-libwin32/win32-pipe/actions/workflows/test.yml)
[![CPAN version](https://img.shields.io/cpan/v/Win32-Pipe)](https://metacpan.org/pod/Win32::Pipe)

Win32 Named Pipe.

This module wraps the Win32 Named Pipes API for inter-process
communication on a single machine or across a network. A server creates
a named pipe and waits for clients; a client opens an existing pipe and
exchanges byte streams with the server.

Dave Roth released the original in 1996. Gurusamy Sarathy folded it
into the `libwin32` bundle, and Jan Dubois split it back out for
separate CPAN release in 2008. The perl-libwin32 organization now
maintains it.

## Documentation

Full reference documentation is on MetaCPAN: <https://metacpan.org/pod/Win32::Pipe>

## Installation

    cpanm Win32::Pipe

## Bug tracker

<https://github.com/perl-libwin32/win32-pipe/issues>

## License

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
