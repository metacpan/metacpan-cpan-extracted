#!perl

use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Correctness Fixes: Wrap Modes, List Continuation, Nested Blockquotes
#===========================================================================

my $conv = Text::MarkdownAdoc->new();

#---------------------------------------------------------------------------
# Wrap mode: none
#---------------------------------------------------------------------------

# Multi-line paragraph joined to one line
{
    my $input    = "This is a long\nparagraph that spans\nmultiple lines.\n";
    my $expected = "This is a long paragraph that spans multiple lines.\n";
    is($conv->convert($input, {wrap => 'none'}), $expected, 'wrap none: multi-line paragraph joined');
}

# Single-line paragraph unchanged
{
    my $input    = "Just one line.\n";
    my $expected = "Just one line.\n";
    is($conv->convert($input, {wrap => 'none'}), $expected, 'wrap none: single-line paragraph unchanged');
}

# Hard line break (trailing ' +') preserved across wrap=none
{
    my $input    = "Line one  \nLine two\n";
    # trailing two spaces → ' +' hard break; wrap=none must not merge across it
    my $result = $conv->convert($input, {wrap => 'none'});
    like($result, qr/ \+/, 'wrap none: hard break marker preserved');
}

# Code block content NOT wrapped
{
    my $input = "```\nline one\nline two\n```\n";
    my $expected = "----\nline one\nline two\n----\n";
    is($conv->convert($input, {wrap => 'none'}), $expected, 'wrap none: code block content unchanged');
}

# Passthrough block (++++..++++) NOT wrapped
{
    my $input = "```math\nx^2\n```\n";
    my $result = $conv->convert($input, {wrap => 'none'});
    like($result, qr/\+\+\+\+/, 'wrap none: passthrough block delimiter present');
    like($result, qr/x\^2/,     'wrap none: passthrough block content unchanged');
}

# Table rows NOT wrapped
{
    my $input = "| A | B |\n|---|---|\n| x | y |\n";
    my $result = $conv->convert($input, {wrap => 'none'});
    like($result, qr/\|===/, 'wrap none: table structure preserved');
}

#---------------------------------------------------------------------------
# Wrap mode: ventilate
#---------------------------------------------------------------------------

# Three sentences re-broken one per line
{
    my $input    = "First sentence. Second sentence. Third one.\n";
    my $expected = "First sentence.\nSecond sentence.\nThird one.\n";
    is($conv->convert($input, {wrap => 'ventilate'}), $expected, 'wrap ventilate: sentences split');
}

# Question and exclamation marks also split
{
    my $input    = "Is this right? Yes! Absolutely.\n";
    my $result   = $conv->convert($input, {wrap => 'ventilate'});
    like($result, qr/right\?\n/, 'wrap ventilate: split on ?');
    like($result, qr/Yes!\n/,    'wrap ventilate: split on !');
}

# Code block content NOT ventilated
{
    my $input = "```\nfoo. bar. baz.\n```\n";
    my $expected = "----\nfoo. bar. baz.\n----\n";
    is($conv->convert($input, {wrap => 'ventilate'}), $expected, 'wrap ventilate: code block content unchanged');
}

#---------------------------------------------------------------------------
# Wrap mode: preserve (default — regression guard)
#---------------------------------------------------------------------------

{
    my $input    = "Line one\nLine two\nLine three\n";
    my $expected = "Line one\nLine two\nLine three\n";
    is($conv->convert($input, {wrap => 'preserve'}), $expected, 'wrap preserve: lines unchanged');
}

{
    my $input    = "Line one\nLine two\nLine three\n";
    my $expected = "Line one\nLine two\nLine three\n";
    is($conv->convert($input), $expected, 'wrap default (preserve): lines unchanged');
}

#---------------------------------------------------------------------------
# List item continuation with + marker
#---------------------------------------------------------------------------

# Fenced code block attached to list item
{
    my $input = "- item one\n\n  ```\n  code\n  ```\n\n- item two\n";
    my $result = $conv->convert($input);
    like($result, qr/\* item one/,  'list continuation: item one present');
    like($result, qr/^\+$/m,        'list continuation: + marker emitted');
    like($result, qr/^----$/m,      'list continuation: code block delimiter present');
    like($result, qr/^code$/m,      'list continuation: code content dedented');
    like($result, qr/\* item two/,  'list continuation: item two present after block');
}

# Fenced code with language attached to list item
{
    my $input = "- step one\n\n  ```perl\n  print 1;\n  ```\n\n- step two\n";
    my $result = $conv->convert($input);
    like($result, qr/\[source,perl\]/, 'list continuation: language attribute preserved');
    like($result, qr/^\+$/m,           'list continuation: + marker with language block');
}

# Plain 4-space indented code after list blank line is DETACHED (existing behavior)
{
    my $input    = "- item one\n\n    code\n";
    my $expected = "* item one\n\n....\ncode\n....\n";
    is($conv->convert($input), $expected, 'list: 4-space indented code after blank is detached');
}

#---------------------------------------------------------------------------
# Nested blockquotes
#---------------------------------------------------------------------------

# Mixed depth: outer depth-1, inner depth-2 → recursive nesting
{
    my $input  = "> outer\n> > inner\n";
    my $result = $conv->convert($input);
    like($result, qr/^____$/m,  'nested blockquote: outer ____ delimiter');
    like($result, qr/outer/,    'nested blockquote: outer content present');
    like($result, qr/inner/,    'nested blockquote: inner content present');
    # Inner quote is processed recursively so it also gets ____ delimiters
    my @delims = ($result =~ /^____$/mg);
    cmp_ok(scalar @delims, '>=', 4, 'nested blockquote: at least 4 ____ delimiter lines (open+close x2)');
}

# Uniform depth-2 blockquote → ______ (regression guard from t/03)
{
    my $input    = "> > Deep quote\n";
    my $expected = "______\nDeep quote\n______\n";
    is($conv->convert($input), $expected, 'nested blockquote: uniform depth-2 gives ______');
}

# Multi-paragraph blockquote still works
{
    my $input  = "> para one\n>\n> para two\n";
    my $result = $conv->convert($input);
    like($result, qr/para one/, 'blockquote multi-para: first para');
    like($result, qr/para two/, 'blockquote multi-para: second para');
    like($result, qr/^____$/m,  'blockquote multi-para: delimiter present');
}

done_testing();
