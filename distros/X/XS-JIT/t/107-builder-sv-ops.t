#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test SV creation
$b->new_sv_iv('result', '42');
is($b->code, "SV* result = newSViv(42);\n", 'new_sv_iv');
$b->reset;

$b->new_sv_nv('result', '3.14');
is($b->code, "SV* result = newSVnv(3.14);\n", 'new_sv_nv');
$b->reset;

$b->new_sv_pv('result', 'hello', 5);
is($b->code, "SV* result = newSVpvn(\"hello\", 5);\n", 'new_sv_pv');
$b->reset;

$b->mortal('sv');
is($b->code, "sv = sv_2mortal(sv);\n", 'mortal');
$b->reset;

# Test SV conversions
$b->sv_to_iv('num', 'sv');
is($b->code, "IV num = SvIV(sv);\n", 'sv_to_iv');
$b->reset;

$b->sv_to_nv('num', 'sv');
is($b->code, "NV num = SvNV(sv);\n", 'sv_to_nv');
$b->reset;

$b->sv_to_pv('str', 'len', 'sv');
my $code = $b->code;
like($code, qr/STRLEN len;/, 'sv_to_pv declares length');
like($code, qr/const char\* str = SvPV\(sv, len\);/, 'sv_to_pv extracts string');
$b->reset;

$b->sv_to_pv('str', undef, 'sv');
is($b->code, "const char* str = SvPV_nolen(sv);\n", 'sv_to_pv without length');
$b->reset;

$b->sv_to_bool('flag', 'sv');
is($b->code, "int flag = SvTRUE(sv);\n", 'sv_to_bool');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->new_sv_iv('r', '0'), $test_b, 'new_sv_iv returns $self');
    is($test_b->new_sv_nv('r', '0'), $test_b, 'new_sv_nv returns $self');
    is($test_b->new_sv_pv('r', 's', 1), $test_b, 'new_sv_pv returns $self');
    is($test_b->mortal('sv'), $test_b, 'mortal returns $self');
    is($test_b->sv_to_iv('r', 'sv'), $test_b, 'sv_to_iv returns $self');
    is($test_b->sv_to_nv('r', 'sv'), $test_b, 'sv_to_nv returns $self');
    is($test_b->sv_to_pv('r', 'l', 'sv'), $test_b, 'sv_to_pv returns $self');
    is($test_b->sv_to_bool('r', 'sv'), $test_b, 'sv_to_bool returns $self');
}

done_testing();
