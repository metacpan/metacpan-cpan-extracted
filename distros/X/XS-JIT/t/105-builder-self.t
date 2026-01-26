#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test get_self patterns
$b->get_self;
is($b->code, "SV* self = ST(0);\n", 'get_self');
$b->reset;

$b->get_self_hv;
my $code = $b->code;
like($code, qr/SV\* self = ST\(0\);/, 'get_self_hv has self');
like($code, qr/HV\* hv = \(HV\*\)SvRV\(self\);/, 'get_self_hv has hv cast');
$b->reset;

$b->get_self_av;
$code = $b->code;
like($code, qr/SV\* self = ST\(0\);/, 'get_self_av has self');
like($code, qr/AV\* av = \(AV\*\)SvRV\(self\);/, 'get_self_av has av cast');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->get_self, $test_b, 'get_self returns $self');
    is($test_b->get_self_hv, $test_b, 'get_self_hv returns $self');
    is($test_b->get_self_av, $test_b, 'get_self_av returns $self');
}

done_testing();
