#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test return_iv
$b->return_iv('result');
my $code = $b->code;
like($code, qr/ST\(0\) = sv_2mortal\(newSViv\(result\)\);/, 'return_iv sets ST(0)');
like($code, qr/XSRETURN\(1\);/, 'return_iv returns 1');
$b->reset;

# Test return_nv
$b->return_nv('result');
$code = $b->code;
like($code, qr/ST\(0\) = sv_2mortal\(newSVnv\(result\)\);/, 'return_nv sets ST(0)');
like($code, qr/XSRETURN\(1\);/, 'return_nv returns 1');
$b->reset;

# Test return_pv with length
$b->return_pv('str', 'len');
$code = $b->code;
like($code, qr/ST\(0\) = sv_2mortal\(newSVpvn\(str, len\)\);/, 'return_pv with length');
$b->reset;

# Test return_pv without length (0)
$b->return_pv('str', undef);
$code = $b->code;
like($code, qr/ST\(0\) = sv_2mortal\(newSVpv\(str, 0\)\);/, 'return_pv without length');
$b->reset;

# Test return_sv
$b->return_sv('my_sv');
$code = $b->code;
like($code, qr/ST\(0\) = my_sv;/, 'return_sv sets ST(0)');
like($code, qr/XSRETURN\(1\);/, 'return_sv returns 1');
$b->reset;

# Test return_yes
$b->return_yes;
$code = $b->code;
like($code, qr/ST\(0\) = &PL_sv_yes;/, 'return_yes sets ST(0) to yes');
like($code, qr/XSRETURN\(1\);/, 'return_yes returns 1');
$b->reset;

# Test return_no
$b->return_no;
$code = $b->code;
like($code, qr/ST\(0\) = &PL_sv_no;/, 'return_no sets ST(0) to no');
like($code, qr/XSRETURN\(1\);/, 'return_no returns 1');
$b->reset;

# Test return_self
$b->return_self;
$code = $b->code;
like($code, qr/ST\(0\) = self;/, 'return_self sets ST(0) to self');
like($code, qr/XSRETURN\(1\);/, 'return_self returns 1');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->return_iv('r'), $test_b, 'return_iv returns $self');
    is($test_b->return_nv('r'), $test_b, 'return_nv returns $self');
    is($test_b->return_pv('s', 'l'), $test_b, 'return_pv returns $self');
    is($test_b->return_sv('sv'), $test_b, 'return_sv returns $self');
    is($test_b->return_yes, $test_b, 'return_yes returns $self');
    is($test_b->return_no, $test_b, 'return_no returns $self');
    is($test_b->return_self, $test_b, 'return_self returns $self');
}

done_testing();
