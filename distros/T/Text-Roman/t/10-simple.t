#!perl
use strict;
use warnings qw(all);

use Test::More;

use Text::Roman qw(:all);

ok(isroman('DCLXVI'), 'isroman');
ok((not isroman(666)), 'not isroman');

ok(ismilhar('L_X_XXIII'), 'ismilhar');
ok((not ismilhar(60023)), 'not ismilhar');

is(roman2int('DCLXVI'), 666, 'roman2int');
is(roman2int('VV'), undef, 'bad roman2int');

is(milhar2int('L_X_XXIII'), 60023, 'milhar2int');
is(milhar2int('X_VV'), undef, 'bad milhar2int');

is(int2roman(666), 'DCLXVI', 'int2roman');
is(int2roman('DCLXVI'), undef, 'bad int2roman 1');
is(int2roman(-666), undef, 'bad int2roman 2');
is(int2roman(4666), undef, 'bad int2roman 3');

my @x = qw[v iii xi iv];
ok(isroman(), qq(isroman($_))) for @x;

done_testing 16;
