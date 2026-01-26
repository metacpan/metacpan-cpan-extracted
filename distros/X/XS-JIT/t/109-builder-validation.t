#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test check_items with exact count
$b->check_items(2, 2, '$self, $arg');
my $code = $b->code;
like($code, qr/if \(items != 2\)/, 'check_items exact count');
like($code, qr/croak_xs_usage/, 'check_items croaks');
$b->reset;

# Test check_items with minimum only
$b->check_items(1, -1, '$self, @args');
$code = $b->code;
like($code, qr/if \(items < 1\)/, 'check_items minimum only');
$b->reset;

# Test check_items with range
$b->check_items(1, 5, '$self, $a, $b?, $c?, $d?');
$code = $b->code;
like($code, qr/if \(items < 1 \|\| items > 5\)/, 'check_items range');
$b->reset;

# Test check_defined
$b->check_defined('sv', 'Value must be defined');
$code = $b->code;
like($code, qr/if \(!SvOK\(sv\)\)/, 'check_defined checks SvOK');
like($code, qr/croak\("Value must be defined"\)/, 'check_defined croaks');
$b->reset;

# Test check_hashref
$b->check_hashref('arg', 'Expected hashref');
$code = $b->code;
like($code, qr/!SvROK\(arg\)/, 'check_hashref checks SvROK');
like($code, qr/SVt_PVHV/, 'check_hashref checks for hash type');
like($code, qr/croak\("Expected hashref"\)/, 'check_hashref croaks');
$b->reset;

# Test check_arrayref
$b->check_arrayref('arg', 'Expected arrayref');
$code = $b->code;
like($code, qr/!SvROK\(arg\)/, 'check_arrayref checks SvROK');
like($code, qr/SVt_PVAV/, 'check_arrayref checks for array type');
like($code, qr/croak\("Expected arrayref"\)/, 'check_arrayref croaks');
$b->reset;

# Test error handling
$b->croak('Something went wrong');
is($b->code, "croak(\"Something went wrong\");\n", 'croak');
$b->reset;

$b->warn('Warning message');
is($b->code, "warn(\"Warning message\");\n", 'warn');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->check_items(1, 1, 'x'), $test_b, 'check_items returns $self');
    is($test_b->check_defined('sv', 'e'), $test_b, 'check_defined returns $self');
    is($test_b->check_hashref('sv', 'e'), $test_b, 'check_hashref returns $self');
    is($test_b->check_arrayref('sv', 'e'), $test_b, 'check_arrayref returns $self');
    is($test_b->croak('msg'), $test_b, 'croak returns $self');
    is($test_b->warn('msg'), $test_b, 'warn returns $self');
}

done_testing();
