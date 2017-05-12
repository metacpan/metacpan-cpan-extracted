
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

my $told = Told::Client->new({
		"host"	=> 'test://abc.de'
		, "tags"	=> ['Pferdchen', 'Giraffe']
		, "type"	=> 'animals'
	});
$told->setConnectionType("GET");

my $result = $told->tell('Told me something');
ok($result =~ m/tags=Pferdchen,Giraffe/, 'Tag is found in query');
ok($result =~ m/etype=animals/, 'Etype is found in query');

done_testing();