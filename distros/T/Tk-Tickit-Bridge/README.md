# Tk-Tickit-Bridge

Connect Perl/Tk keyboard input to a Tickit terminal interface, with a small
helper to service IO::Async while Tk owns the event loop. Extracted from
Audio::Nama.

Tk and Tickit remain separate interfaces in one process. This does not embed
a terminal emulator in a Tk widget.

## Installation

Requires Perl 5.36+, Tk, and Tickit 0.70+. The demo also needs IO::Async,
Tickit::Async, Tickit::Widget::VBox, Tickit::Widget::Static, and
Tickit::Widget::Entry.

```sh
cpanm --installdeps .
perl Build.PL
./Build
./Build test
./Build install
```

Install the optional demo dependencies:

```sh
cpanm IO::Async Tickit::Async Tickit::Widgets
perl examples/bridge-demo.pl
```

The Tk window has two entry fields. The first forwards input into the terminal
entry; the second keeps normal Tk editing. Typing directly into the terminal
works too. Pressing Enter in the terminal entry updates a Tk label. The Tk
button updates the terminal status. Quit with the button, window close,
Ctrl-C, or `/quit` followed by Enter in the terminal entry.

## Minimal connection

After constructing the two interfaces and adding Tickit::Async to your loop:

```perl
my $bridge = Tk::Tickit::Bridge->new(
    widget  => $mw,
    term    => $tickit->term,
    forward => 'outside',
)->install;

my $pump = Tk::Tickit::Bridge::Loop->new(
    widget => $mw,
    loop   => $loop,
)->start;
```

`outside` preserves Nama's policy: forward keys received by Tk when the mouse
pointer is outside the application's Tk windows. Use `always` or a coderef to
choose another policy. No policy captures global keys or changes focus.

Installation attaches a private bindtag to the existing widget subtree. For
widgets added later, call `$bridge->attach($new_widget)`. Call `uninstall` to
remove only this bridge's tags and discard pending input. Keep the bridge and
pump objects alive. See the modules' POD for the complete API.

The pump uses a 10 ms Tk timer and a nonblocking `loop_once(0)`. Callbacks in
both interfaces must return promptly. The application owns Tickit setup and
terminal restoration. The demo requests quit inside callbacks, then cleans up
after returning to the outer event dispatcher.

## Tests

```sh
prove -lr t
xvfb-run -a prove -lr t   # headless X11 integration tests, if Xvfb is installed
```

Tests requiring a display skip when one is unavailable. Unit tests do not
require an X display. Tests never substitute fake Tk or Tickit modules.

## AI notice

Generated with AI assistance.

## License

Copyright (c) 2026 Joel Roth.

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See LICENSE, Artistic, and COPYING.
