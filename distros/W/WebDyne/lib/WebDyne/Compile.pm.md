# WebDyne::Compile #

# NAME #

WebDyne::Compile - compiler for WebDyne `.psp` source files

# SYNOPSIS #

```perl
use WebDyne::Compile;

my $compiler = WebDyne::Compile->new(
    srce => 'page.psp',
);

my $container = $compiler->compile({
    srce => 'page.psp',
});
```

# DESCRIPTION #

`WebDyne::Compile` turns WebDyne source files into the internal container structure used by the runtime. It coordinates `WebDyne::HTML::TreeBuilder`, compile-time Perl and filter stages, optimization passes, metadata extraction, and optional `Storable` output to a cache destination.

The compiler is usually driven indirectly through `WebDyne`, but it can also be used directly for diagnostics and tooling such as `wdcompile`.

# METHODS #

* **new(%options)**

    Construct a compiler-oriented WebDyne object suitable for out-of-request compilation work.

* **compile(\%options)**

    Compile the source file named by `srce`. Optional keys such as `dest`, stage controls, whitespace controls, and other compile flags influence the result.

* **compile_init()**

    Initialize compile-time parser state and shared structures.

* **optimise_one()**

    Run the first optimization pass over the parsed data tree.

* **optimise_two()**

    Run the second optimization pass over the parsed data tree.

* **parse()**

    Parse the source into the container form used by later compile stages.

# OUTPUT #

The compiler returns a two-element container:

* metadata hashref
* compiled page data structure

When a `dest` filename is supplied, the container may also be written to disk in `Storable` form.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
