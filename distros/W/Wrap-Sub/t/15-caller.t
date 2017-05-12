#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Two');
};
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('One::call_1');
    my $x = $wrap->wrap('One::call_0');
    my $y = $wrap->wrap('Two::test4');
    my $z = $wrap->wrap('Two::test5');

    my @call = One::call_0();

    is ($call[0], 'main', "caller(0) direct has correct package");
    like ($call[1], qr/15-caller.t/, "caller(0) direct has correct file");
    is ($call[2], 21, "caller(0) has direct correct line number");
    is ($call[3], 'One::call_0', "caller(0) direct has correct package");

    @call = Two::test4;

    is ($call[0], 'Two', "caller(0) indirect has correct package");
    like ($call[1], qr|t/data/Two.pm|, "caller(0) indirect has correct file");
    is ($call[2], 20, "caller(0) has indirect correct line number");
    is ($call[3], 'One::call_0', "caller(0) indirect has correct package");

    @call = Two::test5;

    is ($call[0], 'main', "caller(1) indirect has correct package");
    like ($call[1], qr|15-caller.t|, "caller(1) indirect has correct file");
    is ($call[2], 35, "caller(1) has indirect correct line number");
    is ($call[3], 'Two::test5', "caller(1) indirect has correct package");

    @call = One::call_1;

    is (ref \@call, 'ARRAY', "caller() going back before trace works");
    is ($call[0], undef, "caller() going back before trace ok");

};

done_testing();
