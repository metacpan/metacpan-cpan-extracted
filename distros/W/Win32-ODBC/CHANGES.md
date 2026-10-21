# Revision history for Win32::ODBC

## 0.037 [2026-10-21]

- Fix crashes after `ODBCShutDown()`, in ithreads started after
  `use Win32::ODBC`, and after `ODBCDisconnect()` with no argument or with 0
  [#12](https://github.com/perl-libwin32/win32-odbc/pull/12)
- Fix crashes when `ODBCConnect()` or `ODBCClone()` fails, and a leaked
  connection and a heap overflow when `ODBCConnect()` cannot set an option
  [#13](https://github.com/perl-libwin32/win32-odbc/pull/13)
- Fix crashes in 13 calls given a connection ID with no connection, such as
  a closed object's; they now report "No such connection"
  [#14](https://github.com/perl-libwin32/win32-odbc/pull/14)
- Make `Sql()`, `FetchRow()` and five other calls report "No such
  connection" for a connection ID with no connection; `Sql()` used to
  succeed on a closed object, and a `FetchRow()` loop never ended
  [#15](https://github.com/perl-libwin32/win32-odbc/pull/15)
- Fix a crash in an `ODBCConfigDSN()` call without attribute arguments, and
  a one-byte overrun of its attribute buffer
  [#16](https://github.com/perl-libwin32/win32-odbc/pull/16)
- Fix XSUB return values on perls built with `PERL_RC_STACK`, and stop
  direct XSUB calls from dropping the values before them in a list
  [#8](https://github.com/perl-libwin32/win32-odbc/pull/8)
- Stop `ODBCShutDown()` and `ODBCInit()` from dropping the values before
  them in a list, make `ODBCInit()` safe to call on Cygwin and MinGW,
  and point the docs at files and pages that still exist
  [#10](https://github.com/perl-libwin32/win32-odbc/pull/10)
- Fix the Cygwin build, and move the repository to the perl-libwin32
  organization. The POD now licenses the module under the same terms as
  Perl itself, as the source files already did
  [#7](https://github.com/perl-libwin32/win32-odbc/pull/7)
- Fix a `-Wwrite-strings` warning by Alex
  ([@asb-capfan](https://github.com/asb-capfan))
  [#6](https://github.com/perl-libwin32/win32-odbc/pull/6)
- Fix the remaining `-Wwrite-strings` warnings, and the `-std=c99` warnings
  on Strawberry Perl 5.40
  [#9](https://github.com/perl-libwin32/win32-odbc/pull/9)
- Fix the compiler warnings in Cygwin builds, and remove the bundled
  `ppport.h`, which Perl 5.6 makes unnecessary
  [#11](https://github.com/perl-libwin32/win32-odbc/pull/11)
- Convert `Changes` to Markdown as `CHANGES.md`

## 0.036 [2020-08-31]

- update pointer variables to work in 64bit as well by Christian Walde ([@wchristian](https://github.com/wchristian)) [#5](https://github.com/perl-libwin32/win32-odbc/pull/5)

## 0.035 [2013-11-28]

- Fix required perl version 5.6 -> 5.006 by Steve Hay ([@steve-m-hay](https://github.com/steve-m-hay)) [#3](https://github.com/perl-libwin32/win32-odbc/pull/3)
- Add Github repo link to `META.yml` by David Steinbrunner ([@dsteinbrunner](https://github.com/dsteinbrunner)) [#1](https://github.com/perl-libwin32/win32-odbc/pull/1)
- Typo fixes by David Steinbrunner ([@dsteinbrunner](https://github.com/dsteinbrunner)) [#2](https://github.com/perl-libwin32/win32-odbc/pull/2)

## 0.034 [2008-06-13]

- moved `sample.pl` to `eg/` subdirectory to avoid the file from
  getting installed.

## 0.033 [2008-04-15]

- new version 0.033 for separate upload to CPAN
- updated email addresses
- simplified `Makefile.PL`
- added `Changes`, `META.yml` and `ppport.h` files
- renamed `Test.pl` to `sample.pl` because it doesn't generate TAP output
- `ODBC/ODBC.xs`: use `iodbcinst.h` with CYGWIN, by Reini Urban
- `ODBC/ODBC.xs` (`_NT_ODBC_Error`): use the correct `SQLINTEGER`, ...
  types in `SQLError` and not the wrong from MSVC, by Reini Urban

Older changes can be found in the `HISTORY.TXT` file.
