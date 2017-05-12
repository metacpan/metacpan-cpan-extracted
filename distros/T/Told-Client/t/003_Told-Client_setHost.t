
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');
$told->setHost('test://told-logrecorder.de/');
my $p = $told->getParams();

is($p->{'host'}, 'test://told-logrecorder.de/', 'Host is set');

done_testing();