# Validation of version 0.001

Checked on Linux with Perl 5.38.2, Tk 804.036, Tickit 0.73,
Tickit::Async 0.25, IO::Async 0.803, Tickit::Widgets 0.39, and
Module::Build::Tiny 0.047.

- `perl Build.PL` and `./Build` succeeded.
- `./Build test`: all 52 assertions passed with an Xvfb display.
- The tests exercise real Tk bindings and idle/timer callbacks, translation,
  consumption, preservation of unrelated bindings, uninstall, and the real
  Tickit::Term XS key injection API. Recording doubles cover error delivery
  and reentrant queuing independently of terminal rendering.
- The standalone demo ran under Xvfb with a pseudoterminal. Terminal text
  entry, Enter submission, `/quit`, and terminal restoration were checked.

Without an X display, the Tk integration test skips. The remaining tests still
require the installed Tk and Tickit Perl modules, but do not open a display.
The initial release has not been checked on other operating systems or Perl
versions. The demo uses standard Tickit widgets, not Nama's modified widgets.

Build commands and demo dependencies are in README.md. The distribution has
not been uploaded to CPAN.
