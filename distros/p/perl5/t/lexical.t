use lib (-e 't' ? 't' : 'test') . '/lib';

use Test::More 0.88;

BEGIN { plan skip_all => 'Perl version too low to test switch feature' unless $] >= 5.010 };

use perl5-tlex;


eval '$f = 1';
like $@, qr/requires explicit package name/, 'got strict';

eval '6 + "fred"';
like $@, qr/isn't numeric/, 'got fatal warnings';

# eval 'given (1) { when (1) {} }';
# is $@, '', 'switch syntax imported';


done_testing;
