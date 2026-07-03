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