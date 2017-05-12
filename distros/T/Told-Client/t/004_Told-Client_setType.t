
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');
$told->setType('TEST');
my $p = $told->getParams();

is($p->{'type'}, 'TEST', 'type is set');

done_testing();