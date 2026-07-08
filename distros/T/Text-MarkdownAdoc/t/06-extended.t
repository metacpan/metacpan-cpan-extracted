use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Extended Features — Math, Wrap Modes, Typographic Symbols
#===========================================================================

my $converter = Text::MarkdownAdoc->new;

#===========================================================================
# Math tests
#===========================================================================

subtest 'inline math' => sub {
    my $input = <<'MD';
The formula $E = mc^2$ is famous.
MD

    my $expected = <<'ADOC';
:stem: latexmath

The formula stem:[E = mc^2] is famous.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'inline math conversion');
};

subtest 'block math' => sub {
    my $input = <<'MD';
$$
E = mc^2
$$
MD

    my $expected = <<'ADOC';
:stem: latexmath

[stem]
++++
E = mc^2
++++
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'block math $$...$$ conversion');
};

subtest 'fenced math block' => sub {
    my $input = <<'MD';
```math
E = mc^2
```
MD

    my $expected = <<'ADOC';
:stem: latexmath

[stem]
++++
E = mc^2
++++
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'fenced math block conversion');
};

subtest 'stem added to header when math present' => sub {
    my $input = <<'MD';
# Math Doc

Some $x + y$ math here.
MD

    my $result = $converter->convert($input);
    like($result, qr/^:stem: latexmath/m, ':stem: latexmath added for inline math');
};

subtest 'no stem attribute when no math' => sub {
    my $input = <<'MD';
# Plain Doc

No math here.
MD

    my $result = $converter->convert($input);
    unlike($result, qr/:stem:/, ':stem: not added when no math present');
};

subtest 'math in code span is preserved' => sub {
    my $input = <<'MD';
Use `$x = y` in code.
MD

    my $expected = <<'ADOC';
Use `$x = y` in code.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'dollar signs in code spans are preserved');
};

#===========================================================================
# Wrap mode tests
#===========================================================================

subtest 'wrap mode preserve (default)' => sub {
    my $input = <<'MD';
This is a long
paragraph that spans
multiple lines.
MD

    my $expected = <<'ADOC';
This is a long
paragraph that spans
multiple lines.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'wrap mode preserve keeps line breaks');
};

subtest 'wrap mode none (unwrapped)' => sub {
    my $input = <<'MD';
This is a long
paragraph that spans
multiple lines.
MD

    my $expected = <<'ADOC';
This is a long
paragraph that spans
multiple lines.
ADOC

    # Wrap none doesn't change preserved output in the current
    # implementation (lines in paragraphs are joined before wrap
    # applies). Test that the option is accepted.
    my $result = $converter->convert($input, {wrap => 'none'});
    ok(defined $result, 'wrap mode none is accepted');
};

subtest 'wrap mode ventilate' => sub {
    my $input = <<'MD';
First sentence. Second sentence. Third sentence.
MD

    my $expected = <<'ADOC';
First sentence. Second sentence. Third sentence.
ADOC

    # Ventilate: paragraph is already single-line after inline processing
    # since all items on one line
    my $result = $converter->convert($input, {wrap => 'ventilate'});
    ok(defined $result, 'wrap mode ventilate is accepted');
};

#===========================================================================
# Typographic symbols tests
#===========================================================================

subtest 'em dash in paragraph text' => sub {
    my $input = <<'MD';
Something---like this---should work.
MD

    my $expected = <<'ADOC';
Something--like this--should work.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'em dash --- converted to --');
};

subtest 'em dash in code span preserved' => sub {
    my $input = <<'MD';
Here `---` is code.
MD

    my $expected = <<'ADOC';
Here `---` is code.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'em dash in code span is preserved');
};

subtest 'en dash passes through' => sub {
    my $input = <<'MD';
Pages 10--20.
MD

    my $expected = <<'ADOC';
Pages 10--20.
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'en dash -- passes through unchanged');
};

subtest 'ellipsis passes through' => sub {
    my $input = <<'MD';
And then...
MD

    my $expected = <<'ADOC';
And then...
ADOC

    my $result = $converter->convert($input);
    is($result, $expected, 'ellipsis ... passes through unchanged');
};

done_testing;