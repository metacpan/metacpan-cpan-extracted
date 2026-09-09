# Text::AsciidocDown

Text::AsciidocDown is a pure Perl, lightweight AsciiDoc-to-Markdown converter.

It was inspired by [opendevise/downdoc](https://github.com/opendevise/downdoc)
and aims to provide dependency-minimal AsciiDoc conversion using only core Perl
modules.

The module transforms practical AsciiDoc documents into Markdown with support
for include pre-merge expansion, parser conversion, and reference rewrite
passes through a single OO interface.

## Installation

    perl Makefile.PL
    make
    make test
    make install

## Dependencies

Text::AsciidocDown requires Perl 5.16.0 or later. All dependencies are core
Perl modules — no non-core CPAN packages are required.

## Usage

```perl
use Text::AsciidocDown;

my $converter = Text::AsciidocDown->new(
    attributes => {
        'markdown-list-indent' => 4,
    },
);

my $asciidoc = <<'ASCIIDOC';
= Hello, AsciidocDown

This is a *paragraph* with `inline` formatting.

== Section

Here is a list:

* one
* two
* three
ASCIIDOC

my $markdown = $converter->convert($asciidoc);
print $markdown;
```

Output:

```
# Hello, AsciidocDown

This is a *paragraph* with `inline` formatting.

## Section

Here is a list:

* one
* two
* three
```

### CLI

The distribution includes a CLI script:

    perl script/asciidoc-down README.adoc
    perl script/asciidoc-down -o - README.adoc
    perl script/asciidoc-down -a env=perl -a env-perl README.adoc

## Typographic Quotes

AsciiDoc's paired quote syntax has two forms: `"`text`"` (double-quoted)
and `'`text`'` (single-quoted). Each is controlled by its own attribute:

| Attribute | Governs | Default |
| --- | --- | --- |
| `quotes` | `"`text`"` | `“ ”` (U+201C / U+201D) |
| `quotes-single` | `'`text`'` | `‘ ’` (U+2018 / U+2019) |

Each attribute value is a space-separated open/close pair, e.g.:

```perl
my $converter = Text::AsciidocDown->new(
    attributes => {
        quotes        => '<q> </q>',
        'quotes-single' => '<q> </q>',
    },
);
```

The real-curly-character default (rather than the `<q></q>` HTML used by
the `downdoc` project this module is modeled after) is deliberate: it is
what makes an AsciiDoc -> Markdown -> AsciiDoc -> Markdown round trip
through `Text::MarkdownAdoc` stable, and it keeps the single- and
double-quoted forms visually distinct. `downdoc` itself uses one shared
`quotes` attribute (default `<q> </q>`) for both forms, so if you need
that exact shared behavior, set both attributes above to the same value.
See `docs/COMPATIBILITY_REPORT.md` for the full rationale.

Inline AsciiDoc passthrough (`+++text+++`) is emitted verbatim: no `<`
escaping, no quote/format substitution, no attribute or macro expansion
inside it. This matters in particular if you use the shared `<q></q>`
downdoc-parity setting above, since `Text::MarkdownAdoc` wraps that raw
HTML as `+++<q>+++...+++</q>+++` passthrough on the way back to AsciiDoc;
without verbatim passthrough handling, a second conversion pass would
corrupt that content.

## Scope and Limitations

- Practical AsciiDoc to Markdown conversion for common technical-doc patterns.
- Not a full AsciiDoc implementation.
- Some advanced syntactic edge cases are intentionally deferred.
- Include pre-merge supports local filesystem includes with tag and lines
  selectors.

## Issues

Report issues at https://github.com/spatocs/asciidoc-down/issues.

## License

Same terms as Perl itself (GNU General Public License or Artistic License).