# Text::KDL::XS

A fast Perl XS binding to [ckdl](https://github.com/tjol/ckdl) for parsing
and emitting [KDL](https://kdl.dev) documents. Supports KDL v1 and v2 with
automatic version detection.

## NAME

Text::KDL::XS - parse and emit KDL Document Language with libckdl

## What is KDL?

KDL ("cuddle" - the **K**DL **D**ocument **L**anguage) is a small,
human-friendly configuration language. It looks a bit like a cleaned-up mix
of JSON and an XML-ish s-expression: every line is a *node* with a name,
optional *arguments*, optional *properties* (`key=value` pairs), and an
optional block of child nodes.

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

In that snippet:

- `package` is a node with one **argument** (`"kdl-rs"`) and a child block.
- `version` is a child node with one argument.
- `author` has one argument (`"Kat Marchán"`) and one **property**
  (`email="kat@example.com"`).
- `keywords` has three arguments - KDL nodes can carry as many as you want.
- `license` has both an argument and its own children.

KDL also supports typed values (`(u32)42`, `(date)"2026-04-29"`), booleans
(`#true`/`#false` in v2, `true`/`false` in v1), `#null`, and several number
formats including arbitrary-precision integers. See
[the KDL spec](https://github.com/kdl-org/kdl) for the full grammar.

## SYNOPSIS

### Parsing

```perl
use Text::KDL::XS qw(parse_kdl);

my $doc = parse_kdl(<<'KDL');
package "thing" {
    version "1.0"
    author "Kat" email="kat@example.com"
}
KDL

for my $node (@{ $doc->nodes }) {
    say $node->name;                      # "package"
    for my $child (@{ $node->children }) {
        say "  ", $child->name;           # "version", "author"
        say "    arg: ", $child->args->[0]->as_string;
        if (my $email = $child->prop('email')) {
            say "    email: ", $email->as_string;
        }
    }
}
```

`parse_kdl` accepts a string, a filehandle/IO object, or a code reference
that returns chunks of bytes. The version is auto-detected by default; pass
`version => '1'` or `version => '2'` to force one.

```perl
my $doc = parse_kdl($string);
my $doc = parse_kdl(\*STDIN);
my $doc = parse_kdl($io_object);
my $doc = parse_kdl(sub { read_some_bytes() });
my $doc = parse_kdl($string, version => '2');
```

### Emitting

The emitter has two modes, chosen automatically from the input.

**Tree mode** (full fidelity) takes a `Document`, a `Node`, or an arrayref
of `Node` objects:

```perl
use Text::KDL::XS qw(emit_kdl);

my $kdl = emit_kdl($doc);                  # Document round-trip
my $kdl = emit_kdl($doc, indent => 4);
```

**Data mode** (convenience) takes any other hashref or arrayref of plain
Perl data:

```perl
my $kdl = emit_kdl({
    package => 'kdl-rs',
    version => '1.0',
    authors => [ 'Kat', 'Sam' ],           # multiple args on one node
    meta    => {                           # nested hash -> child block
        license => 'MIT',
        year    => 2026,
    },
});
```

Produces something like:

```kdl
authors "Kat" "Sam"
meta {
    license "MIT"
    year 2026
}
package "kdl-rs"
version "1.0"
```

Hash keys are emitted in sorted order for deterministic output. Arrays of
hashrefs become repeated sibling nodes:

```perl
emit_kdl({
    author => [
        { name => 'Kat', email => 'kat@example.com' },
        { name => 'Sam' },
    ],
});
```

```kdl
author {
    email "kat@example.com"
    name  "Kat"
}
author {
    name "Sam"
}
```

For booleans, pass an explicit boolean object - strings like `"true"` are
**not** auto-promoted:

```perl
use JSON::PP ();
emit_kdl({ enabled => JSON::PP::true(), debug => JSON::PP::false() });
```

### Streaming

For SAX-like access without building a tree, use the parser directly:

```perl
use Text::KDL::XS::Parser;

my $p = Text::KDL::XS::Parser->new(\*STDIN);
while (my $ev = $p->next_event) {
    if ($ev->{event} eq 'start_node') {
        say "node: ", $ev->{name};
    }
    elsif ($ev->{event} eq 'argument') {
        say "  arg: ", $ev->{value}->as_string;
    }
    elsif ($ev->{event} eq 'property') {
        say "  prop: $ev->{name} = ", $ev->{value}->as_string;
    }
}
```

## INSTALLATION

From a checkout:

```sh
perl Makefile.PL
make
make test
```

`Text::KDL::XS` links statically against the `ckdl` C library through the
sibling `Alien::ckdl` distribution, so no system package is required.

## STATUS

Pre 1.000. The full test suite passes and the API has stabilized around the
`parse_kdl` / `emit_kdl` pair plus the `Parser`, `Document`, `Node`, and
`Value` classes - but minor adjustments are still possible before a 1.000
release. Builds against the pinned ckdl commit shipped by `Alien::ckdl`.

## API OVERVIEW

| Module                                                   | Role                                         |
|----------------------------------------------------------|----------------------------------------------|
| [`Text::KDL::XS`](lib/Text/KDL/XS.pm)                    | Top-level functions: `parse_kdl`, `emit_kdl` |
| [`Text::KDL::XS::Parser`](lib/Text/KDL/XS/Parser.pm)     | Streaming event iterator                     |
| [`Text::KDL::XS::Document`](lib/Text/KDL/XS/Document.pm) | Top-level `nodes` container                  |
| [`Text::KDL::XS::Node`](lib/Text/KDL/XS/Node.pm)         | A node: name, args, props, children          |
| [`Text::KDL::XS::Value`](lib/Text/KDL/XS/Value.pm)       | A typed scalar value                         |

Read the embedded POD (`perldoc Text::KDL::XS`, etc.) for the per-module
reference.

## FEATURES

- High-level tree API (`parse_kdl` / `emit_kdl`) with full round-trip.
- Streaming event API for memory-bounded ingestion of large documents.
- Sources: strings, filehandles, blessed IO objects, code references.
- Faithful KDL value model: per-value type annotations, distinct
  bool/null, integer/float/bigint preservation.
- KDL v1 and v2, auto-detected (`version => '1' | '2' | 'detect'`).
- Plain-Perl data emission for the common "I just want config out" case.

## SEE ALSO

- [`ckdl`](https://github.com/tjol/ckdl) - the underlying C library
- [KDL spec](https://github.com/kdl-org/kdl)
- [`Alien::ckdl`](https://github.com/davenonymous/perl-alien-ckdl) - sibling Alien distribution

## LICENSE

This Perl distribution is released under the same terms as Perl itself.
The bundled `ckdl` library (linked statically through `Alien::ckdl`) is
MIT-licensed.
