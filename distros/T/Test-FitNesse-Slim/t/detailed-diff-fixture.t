use strict;
use warnings;
use Test::More;

use lib 't/lib';

my $class = 'Fitnesse::Slim::Test::DetailedDiff';
my $loaded = eval "require $class; 1";
ok($loaded, 'load upstream DetailedDiff fixture');
if (!$loaded) {
    diag $@;
    done_testing;
    exit;
}

my $fixture = $class->new;
is($fixture->echo('abc'), 'abc', 'echo returns its argument');
$fixture->set_actual_string('text');
is($fixture->expected_string, 'text', 'expectedString returns the set string');
$fixture->set_actual_int(17);
is($fixture->expected_int, 17, 'expectedInt returns the set integer');
$fixture->set_actual_double('1.25');
is($fixture->expected_double, '1.25', 'expectedDouble returns the set double');
$fixture->set_actual_symbol('$answer');
is($fixture->expected_symbol, '$answer', 'expectedSymbol returns the set symbol text');

done_testing;
