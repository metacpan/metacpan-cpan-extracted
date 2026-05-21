# Revision history for Win32::Pipe

## 0.027 [2026-05-18]

- Move repository to the perl-libwin32 GitHub organization [#3](https://github.com/perl-libwin32/win32-pipe/pull/3)
- Fix off-by-one write past the end of the error-message buffer
- Add a test suite covering module load, server-pipe construction, and a client/server round-trip

## 0.026 [unreleased]

- Correct szError type from `LPSTR[]` to `CHAR[]` by Shaun Lowry ([@shaunmlowry](https://github.com/shaunmlowry)) [#2](https://github.com/perl-libwin32/win32-pipe/pull/2)
- Add const to string-literal parameters in `Pipe.xs` to silence `-Wwrite-strings` warnings
