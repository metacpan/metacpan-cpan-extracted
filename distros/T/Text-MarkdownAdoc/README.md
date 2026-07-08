# Text::MarkdownAdoc

## Project Description

`Text::MarkdownAdoc` is a pure Perl converter that transforms Markdown
documents into clean AsciiDoc output suitable for use with Asciidoctor.

The primary target dialect is GitHub-Flavored Markdown (GFM) plus
kramdown extensions (definition lists, footnotes).  Pure CommonMark is
also supported as a subset.

This project is inspired by [kramdown-asciidoc](https://github.com/asciidoctor/kramdown-asciidoc)
(a Ruby reference implementation) and is designed for round-trip compatibility with
[Text::AsciidocDown](https://github.com/spatocs/asciidoc-down) (AsciiDoc → Markdown).

## Installation

```
perl Makefile.PL
make
make test
make install
```

## Requirements

* Perl 5.016 or later
* No non-core dependencies
* `Test::More` for running the test suite

## Usage

### Library API

```perl
use Text::MarkdownAdoc;

my $converter = Text::MarkdownAdoc->new(
    attributes => { 'toc' => 'auto' },
);

my $asciidoc = $converter->convert($markdown_text, {
    attributes => { 'imagesdir' => 'img' },
});
```

### CLI

```
# Convert file to sibling .adoc
markdown-adoc input.md

# Output to stdout
markdown-adoc -o - input.md

# Read from stdin, write to stdout
echo "# Hello" | markdown-adoc -

# Set attributes
markdown-adoc -a toc=auto -a imagesdir=img input.md

# Enable auto-generated heading IDs
markdown-adoc --auto-ids input.md
```

## Supported Markdown Features

* Headings: ATX (`#`) and setext (underline) styles
* Paragraphs with hard line breaks
* Inline formatting: bold, italic, code spans, strikethrough
* Links: inline, reference-style, autolinks
* Images: inline and reference-style
* Fenced code blocks with language annotation
* Indented code blocks (outside list context)
* Blockquotes (including nested)
* Unordered and ordered lists (including nested and tight/loose)
* Task lists (GFM checklist items)
* GFM tables with header row and alignment (compact format)
* Thematic breaks
* Inline HTML conversion (known tags) and passthrough (unknown tags)
* Block HTML (comments → AsciiDoc comments; other → passthrough blocks)
* HTML entity handling
* YAML front matter extraction to AsciiDoc header attributes
* Definition lists (kramdown-style `: ` and bold term `**term**::` forms)
* Footnotes (`[^label]` references and `[^label]: text` definitions)
* Admonition detection (blockquote with bold label, or plain paragraph with `Note:` etc.)
* Diagram code blocks (`plantuml`, `mermaid` → `....` delimiter)
* Smart quote conversion (Unicode smart quotes → AsciiDoc typographic syntax)
* Auto-generated heading IDs (opt-in via `auto_ids` option)

## Known Limitations

* Not a full CommonMark spec implementation — targets practical GFM + kramdown extensions
* Indented code blocks are supported outside list context only
* HTML entity conversion is minimal (only `&nbsp;` → `&#160;`)
* Block HTML is passed through, not parsed or converted
* `***bold italic***` and certain deeply-nested formatting combinations may not
```
 produce the expected AsciiDoc output due to overlapping delimiter handling
```
* Full CommonMark left/right-flanking delimiter runs are not implemented;
```
 simple word-boundary constraints are used for italic detection
```

## Intentionally Unsupported Features

* Full CommonMark spec compliance
* HTML table conversion
* Complex HTML parsing/sanitization
* AST or DOM pipeline

## Round-trip Compatibility

This project is designed for round-trip compatibility with
[Text::AsciidocDown](https://github.com/spatocs/asciidoc-down):
AsciiDoc → Markdown (via `Text::AsciidocDown`) → AsciiDoc (via `Text::MarkdownAdoc`)
should produce no data loss.  See [COMPATIBILITY_REPORT](COMPATIBILITY_REPORT.adoc)
for current status.

## Reference Implementation

[kramdown-asciidoc](https://github.com/asciidoctor/kramdown-asciidoc) serves as the
reference implementation for conversion behavior and test scenarios.
The scenario files (`.md` + `.adoc` pairs) in that repository are a valuable
reference for expected conversion output.

## License

This module is licensed under the same terms as Perl itself.
