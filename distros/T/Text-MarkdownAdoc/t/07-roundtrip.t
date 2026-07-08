use 5.016;
use strict;
use warnings;

use Test::More;

#===========================================================================
# Round-Trip Verification Tests
#===========================================================================

# Skip round-trip tests if Text::AsciidocDown is not available
my $has_asciidoc_down = eval {
    require Text::AsciidocDown;
    Text::AsciidocDown->VERSION(0);
    1;
};

if (!$has_asciidoc_down) {
    plan skip_all => 'Text::AsciidocDown not installed; skipping round-trip tests';
}
else {
    plan tests => 8;
}

use Text::MarkdownAdoc;

my $ad2md = Text::AsciidocDown->new;
my $md2ad = Text::MarkdownAdoc->new;

#===========================================================================
# Round-trip: heading + paragraph
#===========================================================================

subtest 'round-trip: heading and paragraph' => sub {
    plan tests => 2;

    my $asciidoc = <<'ADOC';
= Document Title

This is a paragraph with **bold** and _italic_ text.
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    ok(defined $markdown && $markdown ne '', 'AsciiDoc → Markdown succeeded');

    # Verify essential content made the round trip
    my $back = $md2ad->convert($markdown);
    like($back, qr/Document Title/, 'title preserved');
};

#===========================================================================
# Round-trip: list
#===========================================================================

subtest 'round-trip: unordered list' => sub {
    plan tests => 1;

    my $asciidoc = <<'ADOC';
= List Test

* Item one
* Item two
* Item three
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    my $back     = $md2ad->convert($markdown);

    like($back, qr/Item one/, 'list items preserved');
};

#===========================================================================
# Round-trip: table
#===========================================================================

subtest 'round-trip: table' => sub {
    plan tests => 1;

    my $asciidoc = <<'ADOC';
= Table Test

|===
| Name | Value

| Alice | 10
| Bob | 20
|===
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    my $back     = $md2ad->convert($markdown);

    like($back, qr/Alice/, 'table data preserved');
};

#===========================================================================
# Round-trip: code block
#===========================================================================

subtest 'round-trip: code block' => sub {
    plan tests => 1;

    my $asciidoc = <<'ADOC';
= Code Test

[source,ruby]
----
def hello
  puts "world"
end
----
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    my $back     = $md2ad->convert($markdown);

    like($back, qr/hello/, 'code block content preserved');
};

#===========================================================================
# Round-trip: definition list
#===========================================================================

subtest 'round-trip: definition list' => sub {
    plan tests => 1;

    my $asciidoc = <<'ADOC';
= Deflist Test

Term::
    Definition text here.
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    my $back     = $md2ad->convert($markdown);

    like($back, qr/Term/, 'definition list term preserved');
};

#===========================================================================
# Round-trip: admonition
#===========================================================================

subtest 'round-trip: admonition' => sub {
    plan tests => 1;

    my $asciidoc = <<'ADOC';
= Admonition Test

NOTE: This is a note admonition.
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    my $back     = $md2ad->convert($markdown);

    like($back, qr/NOTE/, 'admonition preserved');
};

#===========================================================================
# Deterministic output for repeated runs
#===========================================================================

subtest 'deterministic output across repeated conversions' => sub {
    plan tests => 1;

    my $input = <<'MD';
# Title

Some **bold** text and _italic_ text.

- Item 1
- Item 2

> A blockquote

```ruby
puts "hello"
```

| A | B |
|---|---|
| 1 | 2 |
MD

    my $result1 = $md2ad->convert($input);
    my $result2 = $md2ad->convert($input);
    is($result1, $result2, 'deterministic output for repeated runs');
};

#===========================================================================
# Multi-document round-trip: complex document
#===========================================================================

subtest 'multi-document round-trip: complex structure' => sub {
    plan tests => 5;

    my $asciidoc = <<'ADOC';
= Full Document

== Section One

This is the first section with some *bold* and _italic_ text.

.Here is a list:
* First item
* Second item
* Third item

== Section Two

Here is a code block:

[source,python]
----
def hello():
    print("world")
----

And here is a table:

|===
| Col A | Col B

| 1 | Alpha
| 2 | Beta
|===

NOTE: Important admonition here.
ADOC

    my $markdown = $ad2md->convert($asciidoc);
    ok(defined $markdown, 'complex AsciiDoc → Markdown conversion succeeded');

    my $back = $md2ad->convert($markdown);
    ok(defined $back, 'complex Markdown → AsciiDoc conversion succeeded');

    # Verify key content survived the round trip
    like($back, qr/Full Document|Section One|Section Two/,
         'headings preserved');
    like($back, qr/bold|italic/,
         'formatting content preserved');
    like($back, qr/Alpha|Beta/,
         'table data preserved');
};

done_testing;