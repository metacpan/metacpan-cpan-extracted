# Win32::Process

[![CI](https://github.com/perl-libwin32/win32-process/actions/workflows/test.yml/badge.svg)](https://github.com/perl-libwin32/win32-process/actions/workflows/test.yml)
[![CPAN version](https://img.shields.io/cpan/v/Win32-Process)](https://metacpan.org/pod/Win32::Process)

Create and manipulate processes.

Win32::Process wraps the Windows process-control API — `CreateProcess`,
`WaitForSingleObject`, `TerminateProcess`, and related calls — so a Perl
script can spawn a child process, wait for it, change its priority,
suspend or resume it, or kill it.

## Documentation

Full reference documentation lives on MetaCPAN:
<https://metacpan.org/pod/Win32::Process>

## Installation

    cpanm Win32::Process

## Bug tracker

<https://github.com/perl-libwin32/win32-process/issues>

## License

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
