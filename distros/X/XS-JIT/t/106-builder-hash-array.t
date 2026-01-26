#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test hash operations
$b->hv_fetch('hv', 'name', 4, 'valp');
is($b->code, "SV** valp = hv_fetch(hv, \"name\", 4, 0);\n", 'hv_fetch');
$b->reset;

$b->hv_store('hv', 'name', 4, 'sv');
is($b->code, "(void)hv_store(hv, \"name\", 4, sv, 0);\n", 'hv_store');
$b->reset;

# Test hv_fetch_return
$b->hv_fetch_return('hv', 'name', 4);
my $code = $b->code;
like($code, qr/SV\*\* valp = hv_fetch/, 'hv_fetch_return fetches');
like($code, qr/ST\(0\) = .*valp.*PL_sv_undef/, 'hv_fetch_return sets ST(0)');
like($code, qr/XSRETURN\(1\)/, 'hv_fetch_return returns');
$b->reset;

# Test array operations
$b->av_fetch('av', 'i', 'elemptr');
is($b->code, "SV** elemptr = av_fetch(av, i, 0);\n", 'av_fetch');
$b->reset;

$b->av_store('av', 'i', 'new_sv');
is($b->code, "av_store(av, i, new_sv);\n", 'av_store');
$b->reset;

$b->av_push('av', 'new_elem');
is($b->code, "av_push(av, new_elem);\n", 'av_push');
$b->reset;

$b->av_len('av', 'length');
is($b->code, "I32 length = av_len(av);\n", 'av_len');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->hv_fetch('h', 'k', 1, 'v'), $test_b, 'hv_fetch returns $self');
    is($test_b->hv_store('h', 'k', 1, 'v'), $test_b, 'hv_store returns $self');
    is($test_b->hv_fetch_return('h', 'k', 1), $test_b, 'hv_fetch_return returns $self');
    is($test_b->av_fetch('a', '0', 'v'), $test_b, 'av_fetch returns $self');
    is($test_b->av_store('a', '0', 'v'), $test_b, 'av_store returns $self');
    is($test_b->av_push('a', 'v'), $test_b, 'av_push returns $self');
    is($test_b->av_len('a', 'l'), $test_b, 'av_len returns $self');
}

done_testing();
