#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Wordsmith::Claude::Blog::Reviewer');

my $sample_text = <<'END';
# Test Blog

This is the first paragraph of the test blog post.
It has multiple sentences to test the parsing.

This is the second paragraph.
Also with multiple sentences.

```perl
my $code = "example";
print $code;
```

Final paragraph after the code block.
END

subtest 'Reviewer creation with text' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => $sample_text,
    );

    isa_ok($reviewer, 'Wordsmith::Claude::Blog::Reviewer');
    is($reviewer->text, $sample_text, 'text set');
    ok($reviewer->options, 'has default options');
    ok($reviewer->loop, 'has default loop');
};

subtest 'Reviewer creation with all options' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text        => $sample_text,
        title       => 'Test Title',
        source_file => '/tmp/test.md',
    );

    is($reviewer->title, 'Test Title', 'title set');
    is($reviewer->source_file, '/tmp/test.md', 'source_file set');
};

subtest 'Reviewer requires text' => sub {
    throws_ok {
        Wordsmith::Claude::Blog::Reviewer->new();
    } qr/text/, 'dies without text';
};

subtest 'Reviewer _parse_paragraphs' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => $sample_text,
    );

    my @paragraphs = $reviewer->_parse_paragraphs($sample_text);

    ok(@paragraphs >= 3, 'parses multiple paragraphs');

    # Check that code block is kept together
    my @code_blocks = grep { /^```/ } @paragraphs;
    is(scalar(@code_blocks), 1, 'code block is single paragraph');

    # Code block should contain the full code
    my ($code_para) = grep { /^```perl/ } @paragraphs;
    like($code_para, qr/print \$code/, 'code block contains code');
    like($code_para, qr/```$/, 'code block has closing fence');
};

subtest 'Reviewer _parse_paragraphs with empty lines' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => "First paragraph.\n\n\n\nSecond paragraph.",
    );

    my @paragraphs = $reviewer->_parse_paragraphs($reviewer->text);

    is(scalar(@paragraphs), 2, 'handles multiple empty lines');
    is($paragraphs[0], 'First paragraph.', 'first paragraph correct');
    is($paragraphs[1], 'Second paragraph.', 'second paragraph correct');
};

subtest 'Reviewer callbacks' => sub {
    my $paragraph_called = 0;
    my $progress_called = 0;
    my $complete_called = 0;

    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => $sample_text,
        on_paragraph => sub { $paragraph_called++; return { action => 'approve' }; },
        on_progress  => sub { $progress_called++; },
        on_complete  => sub { $complete_called++; },
    );

    ok($reviewer->has_on_paragraph, 'has on_paragraph callback');
    ok($reviewer->has_on_progress, 'has on_progress callback');
    ok($reviewer->has_on_complete, 'has on_complete callback');
};

subtest 'Reviewer _assemble' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text  => $sample_text,
        title => 'My Blog',
    );

    my @paragraphs = ('First para', 'Second para', 'Third para');
    my $assembled = $reviewer->_assemble(\@paragraphs);

    like($assembled, qr/^# My Blog/, 'has title header');
    like($assembled, qr/First para/, 'has first paragraph');
    like($assembled, qr/Second para/, 'has second paragraph');
    like($assembled, qr/Third para/, 'has third paragraph');
    like($assembled, qr/First para\n\nSecond para/, 'paragraphs separated by blank line');
};

subtest 'Reviewer _assemble without title' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => $sample_text,
    );

    my @paragraphs = ('First para', 'Second para');
    my $assembled = $reviewer->_assemble(\@paragraphs);

    unlike($assembled, qr/^#/, 'no title header when no title');
    like($assembled, qr/^First para/, 'starts with first paragraph');
};

subtest 'Reviewer has review method' => sub {
    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text => $sample_text,
    );

    can_ok($reviewer, 'review');
};

done_testing();
