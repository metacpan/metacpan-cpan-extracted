#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test indentation
$b->line('outer');
$b->indent;
$b->line('inner');
$b->dedent;
$b->line('outer again');
is($b->code, "outer\n    inner\nouter again\n", 'indent/dedent work');
$b->reset;

# Test block_start/block_end
$b->line('func()');
$b->block_start;
$b->line('body;');
$b->block_end;
like($b->code, qr/func\(\)\n\{\n    body;\n\}\n/, 'block_start/block_end work');
$b->reset;

# Test multiple indent levels
$b->line('level0')
  ->indent->line('level1')
  ->indent->line('level2')
  ->dedent->line('level1 again')
  ->dedent->line('level0 again');
my $code = $b->code;
like($code, qr/^level0$/m, 'level0 not indented');
like($code, qr/^    level1$/m, 'level1 indented 4 spaces');
like($code, qr/^        level2$/m, 'level2 indented 8 spaces');
like($code, qr/^    level1 again$/m, 'back to level1');
like($code, qr/^level0 again$/m, 'back to level0');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->indent, $test_b, 'indent returns $self');
    is($test_b->dedent, $test_b, 'dedent returns $self');
    is($test_b->block_start, $test_b, 'block_start returns $self');
    is($test_b->block_end, $test_b, 'block_end returns $self');
}

done_testing();
