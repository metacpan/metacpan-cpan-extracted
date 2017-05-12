
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

my $result = $told->tell('Told me something', 'Test-Type');
ok($result =~ m/etype=Test-Type/, 'Etype 1 is found in query');

$result = $told->tell('Told me something', 'Test-Type', 'Stonehenge');
ok($result =~ m/etype=Test-Type/, 'Etype 2 is found in query');
ok($result =~ m/tags=Stonehenge/, 'Tags as String is found in query');

$result = $told->tell('Told me something', 'Test-Type', ('Stonehenge'));
ok($result =~ m/etype=Test-Type/, 'Etype 3 is found in query');
ok($result =~ m/tags=Stonehenge/, 'Tags as Array with one element is found in query');

$result = $told->tell('Told me something', 'Test-Type', ('Stonehenge', 'GrantCanyon'));
ok($result =~ m/etype=Test-Type/, 'Etype 4 is found in query');
ok($result =~ m/tags=GrantCanyon,Stonehenge/, 'Tags as Array with more elements is found in query');

done_testing();
