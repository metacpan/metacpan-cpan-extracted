
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

my $told = Told::Client->new({
		"host"	=> 'test://abc.de'
	});
$told->setConnectionType('POST');

my $result = $told->tell({
	'message' => {
		'dog' => 'Bruno'
		,'Cat' => 'Lucy'
		, 'Fish' => 'Klaus'
	}
});
ok($result =~ /Bruno/);

done_testing();