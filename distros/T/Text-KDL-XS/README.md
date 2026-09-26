# Text::KDL::XS

A fast Perl XS binding to [ckdl](https://github.com/tjol/ckdl) for parsing
and emitting [KDL](https://kdl.dev) documents. Supports KDL 2.0.0 and the
legacy KDL 1.0.0 with automatic version detection.

The full documentation is in the POD: `perldoc Text::KDL::XS` for the API
reference and `perldoc Text::KDL::XS::Cookbook` for a tour of every KDL
feature with Perl examples. This file is the short version.

## What is KDL?

KDL ("cuddle", the **K**DL **D**ocument **L**anguage) is a small
configuration and data language. A document is a tree of *nodes*; each
node has a name, optional *arguments*, optional *properties*
(`key=value`) and an optional block of child nodes:

```kdl
package "kdl-rs" {
    version "0.4.0"
    author "Kat Marchán" email="kat@example.com"
    keywords "config" "data" "structured"
    license "MIT" {
        url "https://opensource.org/licenses/MIT"
    }
}
```

Values are strings, numbers, `#true`/`#false`, `#null` or the special
numbers `#inf`, `#-inf` and `#nan`, and any value or node can carry a
`(type)` annotation. Comments, multi-line and raw strings,
hexadecimal/octal/binary numbers and `/-` "slashdash" comments round out
the language. The [Cookbook](https://metacpan.org/pod/Text::KDL::XS::Cookbook) shows all of
them.

## Synopsis

```perl
use Text::KDL::XS qw(parse_kdl emit_kdl);

my $doc = parse_kdl(<<'KDL');
server "web-1" port=8080 {
    tls #true
    upstream name="app" weight=3
}
KDL

for my $node (@{ $doc->nodes }) {
    print $node->name, "\n";                          # server
    print $node->args->[0]->as_string, "\n";          # web-1
    print $node->prop('port')->as_number, "\n";       # 8080
    for my $child (@{ $node->children }) {
        print "  ", $child->name, "\n";               # tls, upstream
    }
}

print emit_kdl($doc);                                 # round trip

print emit_kdl({                                      # plain data
    server => { host => 'localhost', port => 8080 },
    tags   => [ 'a', 'b' ],
});
# server {
#     host localhost
#     port 8080
# }
# tags a b
```

`parse_kdl` accepts a Perl character string, a filehandle (any PerlIO
layer), or a code reference returning chunks of UTF-8. `emit_kdl` accepts a
parsed document, a node, a list of nodes, or plain hashes and arrays, and
returns a character string, so `parse_kdl(emit_kdl($data))` round-trips.

For SAX-style streaming without building a tree:

```perl
use Text::KDL::XS::Parser;

open my $fh, '<', 'huge.kdl' or die $!;
my $p = Text::KDL::XS::Parser->new($fh);
while (my $ev = $p->next_event) {
    print $ev->{name}, "\n" if $ev->{event} eq 'start_node';
}
```

## Modules

| Module                                                     | Role                                                   |
|------------------------------------------------------------|--------------------------------------------------------|
| [`Text::KDL::XS`](https://metacpan.org/pod/Text::KDL::XS)                      | `parse_kdl`, `emit_kdl`, options, encoding, errors     |
| [`Text::KDL::XS::Cookbook`](https://metacpan.org/pod/Text::KDL::XS::Cookbook)  | Every KDL feature with KDL and Perl examples; recipes  |
| [`Text::KDL::XS::Parser`](https://metacpan.org/pod/Text::KDL::XS::Parser)       | Streaming event parser                                 |
| [`Text::KDL::XS::Document`](https://metacpan.org/pod/Text::KDL::XS::Document)   | Container for the top-level nodes                      |
| [`Text::KDL::XS::Node`](https://metacpan.org/pod/Text::KDL::XS::Node)           | A node: name, type annotation, args, props, children   |
| [`Text::KDL::XS::Value`](https://metacpan.org/pod/Text::KDL::XS::Value)         | A typed value: null, bool, number, string              |
| [`Text::KDL::XS::Emitter`](https://metacpan.org/pod/Text::KDL::XS::Emitter)     | Internal emitter helpers                               |

## Features

- Tree API (`parse_kdl` / `emit_kdl`) with faithful round-tripping of
  argument order, property order, type annotations and number kinds.
  Floats are written with the shortest text that reads back as the same
  double; integers exactly over the whole 64-bit signed and unsigned range.
- Streaming event API for memory-bounded processing of large documents,
  with optional reporting of comments (including their text) and
  slashdashed elements.
- Sources: strings, filehandles with any PerlIO layer, IO objects, code
  references.
- Complete value model: distinct null and booleans, integers, floats,
  arbitrary-precision numbers kept as text (with exact `Math::BigInt` /
  `Math::BigFloat` conversion), `#inf`/`#-inf`/`#nan`.
- KDL 1.0.0 and 2.0.0, detected automatically or pinned with
  `version => '1' | '2'`; emit in either version.
- Plain-Perl data emission for the "just write my config" case.
- Safe on untrusted input: strict UTF-8 validation, a nesting limit
  (`max_depth`, 512 by default), errors with the parser's reason reported
  at the caller's line, and an emitter that only writes valid KDL.
- Passes the upstream KDL test suites for both versions (the only textual
  differences are the spelling of floats and repeated properties).

## Known issues

The remaining limitations come from the underlying ckdl library: parse
errors carry a reason but no line or column, detection mode is not a
complete KDL v1 parser, a few lenient spots in ckdl's parser (such as
`\u{}` escapes without digits), and a small memory leak in ckdl for every
parsed property (about 32 bytes, relevant only to long-running processes
that parse many documents). Strings that would be written bare but read
back as keywords or numbers (`true`, `-1`) make `emit_kdl` quote the whole
document. All of them are listed in `perldoc Text::KDL::XS`, section
"KNOWN ISSUES AND LIMITATIONS".

Upgrading from 0.001: a string passed to `parse_kdl` is now read as Perl
characters. Code that passed UTF-8 byte strings must decode them first
(`utf8::decode`, `Encode::decode`) or pass the filehandle instead; see
`Changes` for the complete list.

## Installation

```sh
perl Makefile.PL
make
make test
make install
```

`Text::KDL::XS` links statically against ckdl through
[`Alien::ckdl`](https://github.com/davenonymous/perl-alien-ckdl), which
builds the C library from source. No system package is needed; a C11
compiler and a perl with 64-bit integers are.

## Status

Version 0.002 fixes the defects found in 0.001 (see `Changes`; what
remains are the upstream limitations above) and changes one behaviour on
purpose: string sources are character strings. The API
(`parse_kdl`, `emit_kdl`, `Parser`, `Document`, `Node`, `Value`) is
otherwise stable; `Value` gained `as_bignum`.

## See also

- [KDL specification](https://github.com/kdl-org/kdl) and [kdl.dev](https://kdl.dev)
- [ckdl](https://github.com/tjol/ckdl), the underlying C library
- [`Alien::ckdl`](https://github.com/davenonymous/perl-alien-ckdl)

## License

Copyright (C) 2026 Davenonymous.

This Perl distribution is released under the same terms as Perl itself.
The bundled `ckdl` library (linked statically through `Alien::ckdl`) is
MIT-licensed.
