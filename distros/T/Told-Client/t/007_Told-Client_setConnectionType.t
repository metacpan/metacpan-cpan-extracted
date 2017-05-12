
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');

is($told->setConnectionType('POST'), 1, "Can set POST");
is($told->setConnectionType('GET'), 1, "Can set GET");
is($told->setConnectionType('UDP'), 1, "Can set UDP");
is($told->setConnectionType('FAIL'), 0, "Can not set non existing protokolls.");
done_testing();