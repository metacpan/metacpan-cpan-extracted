use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Footnotes, CLI, Hardening
#===========================================================================

my $converter = Text::MarkdownAdoc->new;

#===========================================================================
# Footnote tests
#===========================================================================

subtest 'basic footnote' => sub {
   my $input = <<'MD';
Here is a sentence.[^1]

[^1]: This is the footnote text.
MD

   my $expected = <<'ADOC';
Here is a sentence.footnote:fn1[This is the footnote text.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'basic footnote conversion');
};

subtest 'footnote with inline formatting' => sub {
   my $input = <<'MD';
See the **bold** note.[^a]

[^a]: This has **bold** and _italic_ text.
MD

   my $expected = <<'ADOC';
See the *bold* note.footnote:fna[This has *bold* and _italic_ text.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'footnote with inline formatting');
};

subtest 'multiple footnote references' => sub {
   my $input = <<'MD';
First ref.[^1] Second ref.[^1]

[^1]: The footnote text.
MD

   my $expected = <<'ADOC';
First ref.footnote:fn1[The footnote text.] Second ref.footnote:fn1[]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'multiple references to same footnote');
};

subtest 'multiple different footnotes' => sub {
   my $input = <<'MD';
Note one.[^1] Note two.[^2]

[^1]: First footnote.
[^2]: Second footnote.
MD

   my $expected = <<'ADOC';
Note one.footnote:fn1[First footnote.] Note two.footnote:fn2[Second footnote.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'multiple different footnotes');
};

subtest 'unresolved footnote falls back to literal' => sub {
   my $input = <<'MD';
Here is a sentence.[^missing]
MD

   my $expected = <<'ADOC';
Here is a sentence.[^missing]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'unresolved footnote falls back to literal');
};

subtest 'multi-line footnote definition' => sub {
   my $input = <<'MD';
See note.[^1]

[^1]: This is a multi-line
    footnote definition that
    spans several lines.
MD

   my $expected = <<'ADOC';
See note.footnote:fn1[This is a multi-line footnote definition that spans several lines.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'multi-line footnote definition');
};

subtest 'footnote with code span' => sub {
   my $input = <<'MD';
See `code` note.[^1]

[^1]: Contains `code` span.
MD

   my $expected = <<'ADOC';
See `code` note.footnote:fn1[Contains `code` span.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'footnote with code span');
};

subtest 'footnote with link' => sub {
   my $input = <<'MD';
See note.[^1]

[^1]: See [example](https://example.com) for details.
MD

   my $expected = <<'ADOC';
See note.footnote:fn1[See https://example.com[example] for details.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'footnote with link');
};

subtest 'footnote ID derived from label' => sub {
   my $input = <<'MD';
Text.[^my-label]

[^my-label]: The footnote.
MD

   my $expected = <<'ADOC';
Text.footnote:fnmy_label[The footnote.]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'footnote ID derived from label with non-word chars');
};

subtest 'footnote definition not emitted as body content' => sub {
   my $input = <<'MD';
Paragraph text.

[^1]: This should not appear in body.
MD

   my $expected = <<'ADOC';
Paragraph text.
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'footnote definition not emitted as body content');
};

#===========================================================================
# Hardening: edge case tests
#===========================================================================

subtest 'consecutive headings without blank lines' => sub {
   my $input = <<'MD';
# Heading 1
## Heading 2
### Heading 3
MD

   my $expected = <<'ADOC';
= Heading 1

== Heading 2

=== Heading 3
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'consecutive headings without blank lines');
};

subtest 'list items immediately followed by heading' => sub {
   my $input = <<'MD';
- Item one
- Item two
# Heading after list
MD

   my $expected = <<'ADOC';
* Item one
* Item two

= Heading after list
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'list items followed by heading');
};

subtest 'fenced code block at end of document (no closing fence)' => sub {
   my $input = <<'MD';
```ruby
def hello
  puts "world"
MD

   my $expected = <<'ADOC';
[source,ruby]
----
def hello
  puts "world"
----
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'unclosed fenced code block at end of document');
};

subtest 'blockquote immediately followed by list' => sub {
   my $input = <<'MD';
> A quote

- List item
- Another item
MD

   my $expected = <<'ADOC';
____
A quote
____

* List item
* Another item
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'blockquote followed by list');
};

subtest 'empty link text' => sub {
   my $input = <<'MD';
[](https://example.com)
MD

   my $expected = <<'ADOC';
https://example.com[]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'empty link text');
};

subtest 'empty alt text for image' => sub {
   my $input = <<'MD';
![](img/photo.png)
MD

   my $expected = <<'ADOC';
image::img/photo.png[]
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'empty alt text for block image');
};

subtest 'code spans containing special characters' => sub {
   my $input = <<'MD';
Here is `**bold**` and `_italic_` and `[link](url)` in code.
MD

   my $expected = <<'ADOC';
Here is `**bold**` and `_italic_` and `[link](url)` in code.
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'code spans containing special characters');
};

subtest 'formatting markers at start/end of line' => sub {
   my $input = <<'MD';
**bold at start** of line
end of line **bold at end**
*italic at start* of line
end of line *italic at end*
MD

   my $expected = <<'ADOC';
*bold at start* of line
end of line *bold at end*
_italic at start_ of line
end of line _italic at end_
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'formatting markers at start/end of line');
};

subtest 'formatting markers adjacent to punctuation' => sub {
   my $input = <<'MD';
(**bold in parens**) and *_italic in parens_*.
MD

   my $expected = <<'ADOC';
(*bold in parens*) and __italic in parens__.
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'formatting markers adjacent to punctuation');
};

subtest 'nested formatting combinations' => sub {
   my $input = <<'MD';
***bold italic*** and **_bold italic_** and _**bold italic**_
MD

   my $expected = <<'ADOC';
**bold italic** and *_bold italic_* and _*bold italic*_
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'nested formatting combinations');
};

subtest 'deterministic output for repeated runs' => sub {
   my $input = <<'MD';
# Title

Some **bold** text with _italic_ and `code`.

- List item 1
- List item 2

> A blockquote

```ruby
puts "hello"
```
MD

   my $result1 = $converter->convert($input);
   my $result2 = $converter->convert($input);
   is($result1, $result2, 'deterministic output for repeated runs');
};

subtest 'table at end of document' => sub {
   my $input = <<'MD';
| A | B |
|---|---|
| 1 | 2 |
MD

   my $expected = <<'ADOC';
|===
| A | B

| 1 | 2
|===
ADOC

   my $result = $converter->convert($input);
   is($result, $expected, 'table at end of document');
};

#===========================================================================
# CLI smoke tests
#===========================================================================

subtest 'CLI --help' => sub {
   my $output = `$^X script/markdown-adoc --help 2>&1`;
   my $exit   = $? >> 8;
   is($exit, 0, '--help exits 0');
   like($output, qr/Usage:/, '--help shows usage');
};

subtest 'CLI --version' => sub {
   my $output = `$^X script/markdown-adoc --version 2>&1`;
   my $exit   = $? >> 8;
   is($exit, 0, '--version exits 0');
   like($output, qr/version/, '--version shows version');
};

subtest 'CLI missing input file' => sub {
   my $output = `$^X script/markdown-adoc 2>&1`;
   my $exit   = $? >> 8;
   isnt($exit, 0, 'missing input file exits non-zero');
   like($output, qr/Missing input file/, 'missing input file shows error');
};

subtest 'CLI stdin to stdout' => sub {
   my $input  = "# Hello\n\nWorld\n";
   my $output = `echo '$input' | $^X script/markdown-adoc - 2>&1`;
   my $exit   = $? >> 8;
   is($exit, 0, 'stdin to stdout exits 0');
   like($output, qr/= Hello/, 'stdin to stdout produces output');
};

subtest 'CLI file input to stdout' => sub {
   my $input = "# Test\n\nContent\n";

   # Write temp file
   my $tmpfile = "/tmp/markdown-adoc-test-$$.md";
   open(my $fh, '>', $tmpfile) or die "Cannot write $tmpfile: $!";
   print $fh $input;
   close($fh);

   my $output = `$^X script/markdown-adoc -o - $tmpfile 2>&1`;
   my $exit   = $? >> 8;
   is($exit, 0, 'file input to stdout exits 0');
   like($output, qr/= Test/, 'file input to stdout produces output');

   unlink($tmpfile);
};

subtest 'CLI attribute injection' => sub {
   my $input = "# Test\n\nContent\n";

   my $tmpfile = "/tmp/markdown-adoc-test-$$.md";
   open(my $fh, '>', $tmpfile) or die "Cannot write $tmpfile: $!";
   print $fh $input;
   close($fh);

   my $output = `$^X script/markdown-adoc -a toc=auto -o - $tmpfile 2>&1`;
   my $exit   = $? >> 8;
   is($exit, 0, 'attribute injection exits 0');
   like($output, qr/= Test/, 'attribute injection produces output');

   unlink($tmpfile);
};

subtest 'CLI same file detection' => sub {
   my $tmpfile = "/tmp/markdown-adoc-test-$$.md";
   open(my $fh, '>', $tmpfile) or die "Cannot write $tmpfile: $!";
   print $fh "# Test\n";
   close($fh);

   my $output = `$^X script/markdown-adoc -o $tmpfile $tmpfile 2>&1`;
   my $exit   = $? >> 8;
   isnt($exit, 0, 'same file input/output exits non-zero');
   like($output, qr/cannot be the same file/, 'same file detection shows error');

   unlink($tmpfile);
};

subtest 'CLI --man' => sub {
    my $output = `$^X -Ilib script/markdown-adoc --man 2>&1`;
    my $exit   = $? >> 8;
    is($exit, 0, '--man exits 0');
    like($output, qr/COMMONMARK COMPATIBILITY/, '--man shows CommonMark section');
    like($output, qr/ADVANCED FEATURES/,        '--man shows Advanced Features section');
};

done_testing;
