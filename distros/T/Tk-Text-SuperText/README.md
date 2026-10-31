# Tk::Text::SuperText

## Description

Tk::Text::SuperText is a Perl module that extends and in some ways redefines
the standard Perl/Tk `Tk::Text` widget.
It adds rectangular selections, selection left/right shift, unlimited undo and
redo, auto-indent, 'inline' selection paste, matching parentheses highlight/find,
commands bound via virtual events.

## Author

Send comments, suggestions, flames :) to:

Current maintainer is Alexander Becker.

Originally written by Alessandro Iob.

## Copyright

Copyright (c) 2016-2021 Alexander Becker. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

## Prerequisites

This module is tested with Perl 5.16.3 and Tk804.03.

## How to build and install

Just type:

```sh
perl Makefile.PL
make
make test
make install
```

## Feature example

Set `-readonly => 1` to prevent user edits while keeping selection, copying,
navigation, and programmatic `insert`/`delete` calls available. Toggle it with
`$text->configure(-readonly => 0)` or `$text->readonly(0)`.

Run the interactive playground from the repository root:

```sh
perl eg/feature-sample.pl
```

The prepared scenarios demonstrate rectangular selections, selection shifts,
inline paste, auto-indentation, matching pairs, and undo/redo. Each scenario
includes instructions and an editable scratch buffer. The Read-only checkbox
lets you try the same commands with editing blocked. Switching scenarios or
resetting a sample discards edits. The "Copy demo column" button replaces the
clipboard with sample data.

## TODO

Configurable syntax highlighting (as a separate module???).
