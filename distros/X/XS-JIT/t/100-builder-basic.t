#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

# Test basic construction
my $b = XS::JIT::Builder->new;
isa_ok($b, 'XS::JIT::Builder');
is($b->code, '', 'Empty builder has empty code');

# Test line output
$b->line('int x = 5;');
is($b->code, "int x = 5;\n", 'line() adds line with newline');

# Test reset
$b->reset;
is($b->code, '', 'reset() clears code');

# Test raw output
$b->raw('hello')->raw(' world');
is($b->code, 'hello world', 'raw() adds without newline');
$b->reset;

# Test comment
$b->comment('This is a comment');
is($b->code, "/* This is a comment */\n", 'comment() adds C comment');
$b->reset;

# Test blank line
$b->line('line1')->blank->line('line2');
is($b->code, "line1\n\nline2\n", 'blank() adds blank line');
$b->reset;

# Test fluent chaining
my $result = $b->line('a')->line('b')->line('c');
is($result, $b, 'Methods return $self for chaining');
is($b->code, "a\nb\nc\n", 'Chained calls accumulate');
$b->reset;

# Test indent_width option
my $b2 = XS::JIT::Builder->new(indent_width => 2);
$b2->line('outer')->indent->line('inner');
is($b2->code, "outer\n  inner\n", 'Custom indent_width works');

done_testing();
