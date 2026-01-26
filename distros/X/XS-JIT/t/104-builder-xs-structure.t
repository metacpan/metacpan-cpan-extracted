#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test XS function structure
$b->xs_function('my_func')->xs_preamble->xs_end;
my $code = $b->code;
like($code, qr/XS_EUPXS\(my_func\) \{/, 'xs_function creates XS function');
like($code, qr/dVAR; dXSARGS;/, 'xs_preamble adds dXSARGS');
like($code, qr/PERL_UNUSED_VAR\(cv\);/, 'xs_preamble adds PERL_UNUSED_VAR');
like($code, qr/\}$/, 'xs_end closes function');
$b->reset;

# Test XS return
$b->xs_return(1);
is($b->code, "XSRETURN(1);\n", 'xs_return');
$b->reset;

$b->xs_return_undef;
$code = $b->code;
like($code, qr/ST\(0\) = &PL_sv_undef;/, 'xs_return_undef sets ST(0)');
like($code, qr/XSRETURN\(1\);/, 'xs_return_undef returns 1');
$b->reset;

# Test croak_usage
$b->croak_usage('$self, $foo');
$code = $b->code;
like($code, qr/croak_xs_usage\(cv, "\$self, \$foo"\);/, 'croak_usage');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->xs_function('test'), $test_b, 'xs_function returns $self');
    is($test_b->xs_preamble, $test_b, 'xs_preamble returns $self');
    is($test_b->xs_end, $test_b, 'xs_end returns $self');
    is($test_b->xs_return(1), $test_b, 'xs_return returns $self');
    is($test_b->xs_return_undef, $test_b, 'xs_return_undef returns $self');
    is($test_b->croak_usage('test'), $test_b, 'croak_usage returns $self');
}

done_testing();
