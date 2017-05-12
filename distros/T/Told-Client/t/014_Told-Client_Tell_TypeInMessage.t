
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

my $result = $told->tell({
		'message' 	=> 'Hash message'
		,'type'		=> 'hashType'
	});

ok($result =~ m/etype=hashType/, 'Type is found in query');

done_testing();
