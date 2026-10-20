use strict;
use warnings;
use Test::More;

use lib 't/lib';

my $class = 'Fitnesse::Slim::Test::AddUpChange';
my $loaded = eval "require $class; 1";
ok($loaded, 'load upstream AddUpChange fixture');
if (!$loaded) {
    diag $@;
    done_testing;
    exit;
}

my $fixture = $class->new;
is($fixture->get('total cents?'), '0', 'starts with zero cents');
is($fixture->get('$ total'), '0.00', 'formats the initial dollar total');

$fixture->set('1c', 2);
$fixture->set('5c', 2);
$fixture->set('10c', 4);
is($fixture->get('total cents?'), '52', 'adds coin amounts in cents');
is($fixture->get('$ total'), '0.52', 'formats a fractional dollar total');

$fixture->set('$1', 1);
is($fixture->get('$ total'), '1.52', 'supports the dollar coin name');
$fixture->reset;
is($fixture->get('total cents?'), '0', 'reset clears accumulated state');

my $error = eval { $fixture->set('2c', 1); 1 } ? '' : $@;
like($error, qr/Unknown coin type 2c/, 'unknown coins raise the upstream error');

done_testing;
