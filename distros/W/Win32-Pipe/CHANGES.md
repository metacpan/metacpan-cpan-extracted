# Revision history for Win32::Pipe

## 0.028 [2026-10-20]

- Fix `BufferSize` and `ResizeBuffer` returning undef, and `Error` returning its message as the error number, in list context on perls built with `-DPERL_RC_STACK` [#6](https://github.com/perl-libwin32/win32-pipe/pull/6)
- Fix `Read` clearing the object's pipe handle when it got zero bytes, which kept `Close` from freeing the pipe [#6](https://github.com/perl-libwin32/win32-pipe/pull/6)
- Fix `Disconnect` returning its usage message instead of disconnecting [#7](https://github.com/perl-libwin32/win32-pipe/pull/7)
- Fix `make test` hanging on Cygwin in the round-trip test [#5](https://github.com/perl-libwin32/win32-pipe/pull/5)

## 0.027 [2026-05-18]

- Move repository to the perl-libwin32 GitHub organization [#3](https://github.com/perl-libwin32/win32-pipe/pull/3)
- Fix off-by-one write past the end of the error-message buffer
- Add a test suite covering module load, server-pipe construction, and a client/server round-trip

## 0.026 [unreleased]

- Correct szError type from `LPSTR[]` to `CHAR[]` by Shaun Lowry ([@shaunmlowry](https://github.com/shaunmlowry)) [#2](https://github.com/perl-libwin32/win32-pipe/pull/2)
- Add const to string-literal parameters in `Pipe.xs` to silence `-Wwrite-strings` warnings
