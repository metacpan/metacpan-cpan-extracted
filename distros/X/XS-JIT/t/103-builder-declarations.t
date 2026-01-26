#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test variable declarations
$b->declare('int', 'x', '5');
is($b->code, "int x = 5;\n", 'declare with value');
$b->reset;

$b->declare('int', 'x', undef);
is($b->code, "int x;\n", 'declare without value');
$b->reset;

$b->declare_sv('foo', 'ST(0)');
is($b->code, "SV* foo = ST(0);\n", 'declare_sv');
$b->reset;

$b->declare_hv('bar', 'newHV()');
is($b->code, "HV* bar = newHV();\n", 'declare_hv');
$b->reset;

$b->declare_av('baz', 'newAV()');
is($b->code, "AV* baz = newAV();\n", 'declare_av');
$b->reset;

$b->declare_int('count', '0');
is($b->code, "int count = 0;\n", 'declare_int with value');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->declare('int', 'x', '0'), $test_b, 'declare returns $self');
    is($test_b->declare_sv('s', 'NULL'), $test_b, 'declare_sv returns $self');
    is($test_b->declare_hv('h', 'NULL'), $test_b, 'declare_hv returns $self');
    is($test_b->declare_av('a', 'NULL'), $test_b, 'declare_av returns $self');
    is($test_b->declare_int('i', '0'), $test_b, 'declare_int returns $self');
}

done_testing();
