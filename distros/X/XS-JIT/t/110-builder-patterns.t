#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test method_start
$b->method_start('MyClass_do_thing', 1, 3, '$self, $arg1, $arg2?');
my $code = $b->code;
like($code, qr/XS_EUPXS\(MyClass_do_thing\)/, 'method_start creates function');
like($code, qr/dVAR; dXSARGS;/, 'method_start has preamble');
like($code, qr/if \(items < 1 \|\| items > 3\)/, 'method_start checks items');
like($code, qr/croak_xs_usage.*\$self, \$arg1, \$arg2\?/, 'method_start has usage');
$b->reset;

# Test predicate
$b->predicate('name');
$code = $b->code;
like($code, qr/XS_EUPXS\(has_name\)/, 'predicate function name');
like($code, qr/hv_fetch.*"name".*4/, 'predicate fetches to check existence');
like($code, qr/PL_sv_yes|PL_sv_no/, 'predicate returns bool');
$b->reset;

# Test clearer
$b->clearer('name');
$code = $b->code;
like($code, qr/XS_EUPXS\(clear_name\)/, 'clearer function name');
like($code, qr/hv_delete.*"name".*4/, 'clearer deletes key');
$b->reset;

# Test prebuilt ro_accessor
$b->ro_accessor('MyClass_get_name', 'name', 4);
$code = $b->code;
like($code, qr/XS_EUPXS\(MyClass_get_name\)/, 'ro_accessor function name');
like($code, qr/dXSARGS/, 'ro_accessor has stack args');
like($code, qr/hv_fetch.*"name".*4/, 'ro_accessor fetches attribute with hv_fetch');
like($code, qr/valp \&\& \*valp/, 'ro_accessor checks for valid pointer');
like($code, qr/XSRETURN\(1\)/, 'ro_accessor returns');
$b->reset;

# Test prebuilt rw_accessor
$b->rw_accessor('MyClass_name', 'name', 4);
$code = $b->code;
like($code, qr/XS_EUPXS\(MyClass_name\)/, 'rw_accessor function name');
like($code, qr/if \(items > 1\)/, 'rw_accessor checks items for setter');
like($code, qr/hv_store.*"name".*4/, 'rw_accessor stores with hv_store');
like($code, qr/hv_fetch.*"name".*4/, 'rw_accessor fetches with hv_fetch');
$b->reset;

# Test prebuilt constructor
$b->constructor('MyClass_new', [['name', 4], ['age', 3]]);
$code = $b->code;
like($code, qr/XS_EUPXS\(MyClass_new\)/, 'constructor function name');
like($code, qr/HV\* hv = newHV\(\)/, 'constructor creates hash');
like($code, qr/hv_fetch\(args, "name", 4/, 'constructor processes name attr');
like($code, qr/hv_fetch\(args, "age", 3/, 'constructor processes age attr');
like($code, qr/sv_bless/, 'constructor blesses object');
like($code, qr/XSRETURN\(1\)/, 'constructor returns');
$b->reset;

# Test constructor with no attrs
$b->constructor('Empty_new', []);
$code = $b->code;
like($code, qr/XS_EUPXS\(Empty_new\)/, 'constructor with no attrs works');
like($code, qr/sv_bless/, 'constructor with no attrs blesses');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->method_start('f', 1, 1, 'x'), $test_b, 'method_start returns $self');
    is($test_b->predicate('a'), $test_b, 'predicate returns $self');
    is($test_b->clearer('a'), $test_b, 'clearer returns $self');
    is($test_b->ro_accessor('f', 'a', 1), $test_b, 'ro_accessor returns $self');
    is($test_b->rw_accessor('f', 'a', 1), $test_b, 'rw_accessor returns $self');
    is($test_b->constructor('f', []), $test_b, 'constructor returns $self');
}

done_testing();
