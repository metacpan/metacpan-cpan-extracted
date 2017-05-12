
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

my $told = Told::Client->new({
		"host"	=> 'test://abc.de'
		, "tags"	=> ['abc']
	});
$told->setConnectionType("GET");

my $result = $told->tell('Told me something');
ok($result =~ m/tags=abc/, 'Tag is found in query');

done_testing();