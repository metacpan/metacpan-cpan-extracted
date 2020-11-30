# Tie-Hash-Indexed

Ordered hashes for Perl


## Description

Tie::Hash::Indexed is intentionally very similar to other
ordered hash modules, most prominently Hash::Ordered.
However, Tie::Hash::Indexed is written completely in XS
and is, often significantly, faster than other modules.
For a lot of operations, it's more than twice as fast as
Hash::Ordered, especially when using the object-oriented
interface instead of the tied interface. Other modules,
for example Tie::IxHash, are even slower.

The object-oriented interface of Tie::Hash::Indexed is
almost identical to that of Hash::Ordered, so in most
cases you should be able to easily replace one with the
other.


## Installation

Installation of the Tie::Hash::Indexed module follows the standard
Perl Way and should not be harder than:

    perl Makefile.PL
    make
    make test
    make install

Note that you may need to become superuser to `make install`.

If you're building the module under Windows, you may need to use a
different make program, such as `nmake`, instead of `make`.


## Features

You can enable or disable certain features at compile time by adding
options to the `Makefile.PL` call. However, you can safely leave them
at their default.

Currently, the only available feature is `debug` to build the module
with debugging support. If your perl binary was already built with
debugging support, the `debug` feature is enabled by default.

You can enable or disable features explicitly by adding the arguments

    enable-feature
    disable-feature

to the `Makefile.PL` call. To explicitly build the module with debugging
enabled, you would say:

    perl Makefile.PL enable-debug

This will still allow you to pass other standard arguments to
`Makefile.PL`, like

    perl Makefile.PL enable-debug OPTIMIZE=-O3


## Copyright

Copyright (c) Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

