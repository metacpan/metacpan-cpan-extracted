#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# booleans
{
    use builtin qw( true false );

    ok(true, 'true is true');
    ok(!false, 'false is false');

    my $val = true;
    cmp_ok($val, $_, !!1, "true is equivalent to !!1 by $_") for qw( eq == );
    cmp_ok($val, $_,  !0, "true is equivalent to  !0 by $_") for qw( eq == );

    $val = false;
    cmp_ok($val, $_, !!0, "false is equivalent to !!0 by $_") for qw( eq == );
    cmp_ok($val, $_,  !1, "false is equivalent to  !1 by $_") for qw( eq == );
}

done_testing;
