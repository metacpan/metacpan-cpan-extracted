#!perl
use strict;
use warnings qw(all);

use Test::More;

use Text::Roman qw(:all);

ok(ismroman('L_X_XXIII'), 'ismroman');
is(mroman2int('L_X_XXIII'), 60023, 'mroman2int');
is(roman(666), 'DCLXVI', 'roman');

done_testing 3;
