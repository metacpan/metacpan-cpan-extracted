# etext — a Tk text widget with nestable, editable *blocks*

`etext` is Ilya Zakharevich's extension of the Tk text widget (1995–1997):
in addition to tags, marks and embedded windows, a text can contain
**blocks** — annotations with an internal tree structure whose geometry is
managed by a callback written in the scripting language.  With a few dozen
lines of Perl per block type this gives editable fractions, radicals,
super/subscripts, labeled equations, tables, delimiters that grow with
their contents, and so on, all living inside an ordinary text widget where
every editing command keeps working.  See `doc/etext.pod` for the full
description and `demo/etext.pl` for a demonstration (with a small TeX
import/export).

The last release on CPAN was `etext 1.6.2` (1997), written against the
tk4.0b3 text widget and the Perl/Tk b9 glue.  The first commit of the Git
repository (https://github.com/ilyaz-ai/etext) is that release, untouched.
Everything after it is the modernization described below.

## Status (version 2.01, 2026)

* **The Perl extension `Tk::eText` builds and works with Perl 5.38 and
  Perl/Tk 804.036**, as a standalone module.  The widget is the
  same tk4.0-derived C code with its block machinery; what changed is the
  interface to Tk (fonts, lists, results, callbacks, regexps) and the way
  the module is built and loaded.  It no longer needs a Tk build tree.
* **The memory leaks are fixed** (see below) and there is an automated test
  suite (`t/`), including a leak regression test.
* **The features the Tk text widget acquired after tk4.0 are there**:
  indices count characters (Perl/Tk 804 stores text as UTF-8; the 1997
  code counted bytes, so "1.1" after an "é" pointed into the middle of
  it), the `edit` subcommand (undo/redo, `-undo`, `-maxundo`,
  `-autoseparators`, `edit modified` and `<<Modified>>`), the `image`
  subcommand (embedded images) and the `-elide` tag option.  All of them
  work inside blocks, and the test suite compares their behaviour with
  Tk's own text widget on the same text.  The demo's TeX symbols are
  Unicode characters, not codes in 8-bit symbol fonts.
* The Tcl/Tk flavour (in the Git repository only: `eText/pTk/mTk/`,
  `Makefile.etext`, `demo/etext.tcl`) is kept for reference: it replaces
  core files of tk4.0b3 and cannot be built against a current Tcl/Tk.

## Building and testing

    perl Makefile.PL
    make
    make test            # needs an X display; "xvfb-run make test" works too
    make install

(In the Git repository the distribution lives in `eText/`: `cd eText`
first.)

Requirements: Perl 5.8+, Perl/Tk 804.027+ (with its headers installed, as
every Perl/Tk installation does), a C compiler.  `Test::LeakTrace` is
optional (the leak test skips part of itself without it).

The interactive demo:

    perl -Mblib demo/etext.pl        # before "make install"
    perl demo/etext.pl               # after "make install"

The demo's helper modules `FreezeThaw` and `Text::TeX` are bundled under
`utils/` (they are also on CPAN; the bundled copies are not installed).

## The memory leaks

The leak reported for the widget (growing memory while the text just sits
there with the insertion cursor blinking in a formula) came from the
**block layout callback**: every call built the argument list for the Perl
callback with a fresh reference to the widget object, and that reference
was never released.  The cursor blink re-lays-out the display line holding
the cursor, so with the cursor inside a block the callback runs twice per
second, forever.  A refcount leak of this kind cannot be seen by counting
SVs; it shows up as the widget's Perl object never being freed, which is
what `t/leak.t` checks.

Further leaks found and fixed along the way:

* `TkTextRedrawRegion()` created an X region and never destroyed it.  It is
  called on every focus change (when the insertion cursor is switched on
  and off) and on expose events.
* The "object-oriented dump" (`block list`) leaked one scalar per call, and
  every typed element of the returned structure leaked its payload (a
  reference counted twice).
* The embedded-window entry of the dump leaked a widget reference, and a
  pending value before it.
* Deleting a block type (or destroying the widget) never released the
  block's callbacks, so a `-layoutcmd` closure kept the widget alive; tag
  `-data` was never released; `dump -command` given twice leaked the first
  callback.

A review of the port (six independent readers, each finding verified) also
turned up inherited bugs that were fixed: `tag prevrange` crashed unless the
tag ended on the first line of its B-tree node (and could not look into or
out of blocks), `search -nocase` corrupted the heap on long lines, a layout
callback returning a single row was rejected, `window cget -align` died, and
a few more; see `Changes`.  `t/regress.t` covers them.

What is *not* a leak of this widget: with an extreme blink rate and no X
round trips at all, Perl/Tk 804 itself accumulates `Tk_CreateErrorHandler`
records (also with a plain `Tk::Text`); Tk frees them lazily after the next
round trip with the server.

## Layout of the distribution

    README.md, Changes, BUGS       this file, the change log, known problems
    doc/etext.pod  the documentation of the widget, blocks and -layoutcmd
    eText.pm, eText.xs, Makefile.PL, tkText*.c, tkText.h, pperl.h, ...
    eTextSyms.PL, eTextSyms.h      the symbol-prefix header (committed)
    t/             tests
    demo/          the Perl demo and a sample document
    utils/         FreezeThaw and Text::TeX for the demo

The Git repository holds, besides this directory (`eText/`), the original
1997 top-level files and the Tcl/Tk flavour (historical), the records of
the modernization (`HANDOVER.md`, the `CONVERSATION-*.md` files) and the
Perl/Tk and Tcl/Tk defects met on the way (`TK_BUGS.md`; reports ready
for filing in `UPSTREAM.md` and `upstream/`).  `An` below refers to the
entries of `TK_BUGS.md`.

## Differences from Tk::Text

* Undoing a deletion re-creates the blocks, tags and marks that were in
  the deleted range (Tk's text widget restores the text only), the blocks
  the deletion cut included: the widget dissolves a cut block (its
  remaining leaves become lines), and the undo takes those remains out
  again and re-creates the block whole.  Embedded images and windows are
  re-created too (Tk restores neither): an image whose Tk image is gone
  comes back empty, a window given with `-window` was destroyed with the
  deletion and comes back as an empty window segment, one with `-create`
  is created again when displayed.
* `edit undo` undoes.  In Perl/Tk's own `Tk::Text` the recording of
  changes is compiled out and `edit undo` always says "nothing to
  undo" (undo there is `Tk::TextUndo`, written in Perl).
* `dump` looks into blocks and, with `-block` (part of `-all`), reports a
  `block` element at a block's start and a `blockend` element after it;
  `dump -image` reports the name of the image in the widget, as
  documented (Perl/Tk's `Tk::Text` reports the `-image` argument).
* `+N lines` keeps the character position; Tk keeps the byte offset
  (TK_BUGS.md A5).
* `search -nocase` leaves alone the few characters whose lower-case form
  has another UTF-8 length (U+0130 and the like), so that all other
  matches are reported correctly; Tk goes wrong on such lines
  (TK_BUGS.md A4).
* `block data` accepts the start position of an empty block or of a
  block that is not nested (an empty block has no inside).
* The `display` and `any` index modifiers of Tk 8.5 exist (`+N display
  indices`, `display wordstart`, `display linestart`, `+N display
  lines`, ...), and the widget's cursor keys use them, so the insertion
  cursor skips elided text where `Tk::Text`'s enters it, and Home and
  End go to the ends of the display line.  Unlike Tk 8.6, `display
  wordend` leaves elided text out all the way (TK_BUGS.md A6), and
  `display lines` stops at the last display line of the text (A7).
  `any chars` is the same as `chars`: every position of the index space
  is a character here, as in Tk 8.4.
* Display lines never span logical lines: a line whose newline is elided
  still ends a display line, and an entirely elided line is a display
  line of no height, which `display lines` passes over (Tk 8.5 merges
  such a line with the next one).  The widget wraps as Tk 8.4 does: a
  space at the right margin needs a pixel of room, where Tk 8.5 lets
  it hang over.
