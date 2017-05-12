
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

my $told = Told::Client->new({
		"host"	=> 'test://abc.de'
	});
$told->setConnectionType("GET");
$told->setType("TestType");

my $result = $told->tell('Told me something');
ok($result =~ m/etype=TestType/, 'Type is found in query');

done_testing();
