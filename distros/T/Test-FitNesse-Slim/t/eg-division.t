use strict;
use warnings;
use Test::More;

use lib 't/lib';

BEGIN { use_ok('Eg::Division') }

my $division = Eg::Division->new;
isa_ok($division, 'Eg::Division');
is($division->{numerator}, 0, 'numerator starts at the Java double default');
is($division->{denominator}, 0, 'denominator starts at the Java double default');

$division->set_numerator(10);
$division->set_denominator(2);
cmp_ok($division->quotient, '==', 5, 'quotient divides the current numerator by denominator');
is($division->quotient, '5.0', 'integral quotient preserves Java double formatting');

$division->set_denominator(5);
is($division->quotient, '2.0', 'quotient uses updated state and double formatting');

$division->set_numerator(40);
$division->set_denominator(4);
is($division->quotient, '10.0', 'two-digit integral quotient avoids scientific notation');

$division->set_numerator(21);
$division->set_denominator(5);
is($division->quotient, '4.2', 'non-integral quotient uses concise double formatting');

$division->set_numerator(1);
$division->set_denominator(0);
is($division->quotient, 'Infinity', 'positive division by zero returns Java double infinity');

$division->set_numerator(0);
is($division->quotient, 'NaN', 'zero divided by zero returns Java double NaN');

$division->set_denominator(5);
is($division->set_numerator(16), undef, 'setNumerator has no return value');
is($division->{numerator}, 16, 'setNumerator stores its value in the public field');
is($division->{denominator}, 5, 'setting numerator leaves denominator unchanged');

done_testing;
