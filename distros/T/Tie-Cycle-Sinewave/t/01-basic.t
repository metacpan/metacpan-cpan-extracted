# 01-basic.t
#
# basic tests for Tie::Cycle::Sinewave
#
# Copyright (c) 2005 David Landgren

use strict;
use Tie::Cycle::Sinewave;

use Test::More tests => 31;

{
    tie my $c, 'Tie::Cycle::Sinewave', {
        min       => 20,
        max       => 40,
        period    =>  5,
    };

    cmp_ok( ref(tied $c), 'eq', 'Tie::Cycle::Sinewave', 'we have a T::C::S object' );
}

{
    tie my $x, 'Tie::Cycle::Sinewave',
        min       => -50,
        max       =>  50,
        period    =>  16,
        start_max =>   1,
    ;

    cmp_ok( $x, '==', 50, 'max start 50' );

    cmp_ok( (tied $x)->min, '==', -50, 'min is -50' );
    cmp_ok( (tied $x)->min(-20), '==', -50, 'min is -50, set to -20' );
    cmp_ok( (tied $x)->min, '==', -20, 'min is -20' );

    cmp_ok( (tied $x)->max, '==', 50, 'max is  50' );
    cmp_ok( (tied $x)->max(100), '==', 50, 'max is 50, set to 100' );
    cmp_ok( (tied $x)->max, '==', 100, 'max is  100' );

    cmp_ok( (tied $x)->period, '==', 16, 'period is 16' );
    cmp_ok( (tied $x)->period(20), '==', 16, 'period is 16, set to 20' );
    cmp_ok( (tied $x)->period, '==', 20, 'period is 20' );
}

{
    tie my $y, 'Tie::Cycle::Sinewave', {
        min       =>  50,
        max       => -50,
        start_min =>   1,
    };
    cmp_ok( (tied $y)->min, '==', -50, 'swap min is -50' );
    cmp_ok( (tied $y)->max, '==',  50, 'swap max is  50' );
    cmp_ok( (tied $y)->max(-100), '==', 50, 'max is 50, set to -100' );
    cmp_ok( (tied $y)->min, '==', -100, 'now swap min is -100' );
    cmp_ok( (tied $y)->max, '==',  -50, 'now swap max is  -50' );
    cmp_ok( $y, '==', -100, 'min start -100' );
}

{
    my $at_min = 0;
    my $at_max = 0;
    my $dont_care;

    tie my $cb, 'Tie::Cycle::Sinewave', {
        period   => 20,
        at_max   => sub { ++$at_max },
        at_min   => sub { ++$at_min },
        startmax => 1,
    };

    $dont_care = $cb for 1..11;
    cmp_ok( $at_max, '==', 0, 'not yet past max' );
    cmp_ok( $at_min, '==', 1, 'but past min' );

    $dont_care = $cb for 1..11;
    cmp_ok( $at_max, '==', 1, 'now past max' );
}

{
    my $at_min = 0;
    my $at_max = 0;
    my $dont_care;

    tie my $cb, 'Tie::Cycle::Sinewave', {
        period    => 20,
        atmax    => sub { ++$at_max },
        atmin    => sub { ++$at_min },
        startmin => 1,
    };

    $dont_care = $cb for 1..11;
    cmp_ok( $at_min, '==', 0, 'not yet past min' );
    cmp_ok( $at_max, '==', 1, 'but past max' );

    $dont_care = $cb for 1..11;
    cmp_ok( $at_min, '==', 1, 'now past min' );
}

{
    my $dont_care;
    my $period = 17;

    tie my $d, 'Tie::Cycle::Sinewave', {
        min => 18,
        max => 99,
        period => $period,
        at_min => 'nop',
        at_max => 'nop',
    };

    my $first  = $d;
    my $angle  = (tied $d)->angle;
    $dont_care = $d for 1 .. ($period - 1);

    cmp_ok( abs($first - $d), '<', 1e-3, 'back to where we started' );

    my $now  = (tied $d)->angle;
	my $error = abs($angle - $now);
	$error -= Tie::Cycle::Sinewave::PI_2 if $error > Tie::Cycle::Sinewave::PI;
    cmp_ok( $error, '<', 1e-3, 'angle check' )
		or diag("angle=$angle, now=$now");

    my $next = $d;

    ok( not( exists( (tied $d)->{at_min} )), 'at_min not defined for garbage' );
    ok( not( exists( (tied $d)->{at_max} )), 'at_max not defined for garbage' );

    $dont_care = $d for 1 .. 10;
    $d = $angle;

    cmp_ok( abs($next - $d), '<', 1e-3, 'STORE check' );
}

{
    my $dont_care;

    tie my $p, 'Tie::Cycle::Sinewave', {
        min => 18,
        max => 90,
        period => 0,
    };

    cmp_ok( (tied $p)->period,    '==', 1, 'zero-length period changed to 1' );
    cmp_ok( (tied $p)->period(0), '==', 1, 'period is 1, set to 0' );
    cmp_ok( (tied $p)->period,    '==', 1, 'zero-length period changed to 1 again' );
}

