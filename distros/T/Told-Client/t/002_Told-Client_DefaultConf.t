
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new({
		'host' => 'test://told-logrecorder.de/'
	}), 'Can create instance of Told::Client');
my $p = $told->getParams();
is ($p->{'host'}, 'test://told-logrecorder.de/', 'Host is set on initialisation with param');
is ($p->{'type'}, '', 'Type is empty initialisation with param');
is ($p->{'defaulttags'}, undef, 'defaulttags is undef initialisation with param');
is ($p->{'tags'}, undef, 'tags is undef initialisation with param');


ok( $told = Told::Client->new({
		'host' 			=> 'test://told-logrecorder.de/'
		, 'type' 		=> 'TEST'
		, 'defaulttags'	=> ["honigkuchen"]
		, 'tags'		=> ['zuckerschlecken', 'bauernhof']
	}), 'Can create instance of Told::Client');
$p = $told->getParams();
is ($p->{'host'}, 'test://told-logrecorder.de/', 'Host is set on initialisation with param');
is ($p->{'type'}, 'TEST', 'Type is filled on initialisation with param');
is (@{$p->{'defaulttags'}}[0], 'honigkuchen', 'defaulttags is not undef initialisation with param');
is (@{$p->{'tags'}}[0], 'zuckerschlecken', 'tags has zuckerschlecken after initialisation with param');
is (@{$p->{'tags'}}[1], 'bauernhof', 'tags has bauernhof after initialisation with param');

done_testing();