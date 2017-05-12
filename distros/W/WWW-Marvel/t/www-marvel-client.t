# -*- perl -*-

use Test::More tests => 7;

BEGIN { use_ok( 'WWW::Marvel::Client' ); }

my $client = WWW::Marvel::Client->new({ public_key => 1234, private_key => 'abcd' });
# write a test for this croaking condition
# $client->hash();

$client->set_timestamp(1431297266);
is($client->get_timestamp, 1431297266, "get timestamp");
is($client->hash, '0d9b0a1ffe216482153a667fb4b68dac', 'md5 hash with ts = 1431297266');
is($client->hash(1), 'ffd275c5130566a2916217b101f26150', 'md5 hash with ts = 1');

my $uri = $client->uri({path => ''});
diag $uri;
like($uri, qr/ts=1431297266/, 'ts is in query params');
like($uri, qr/apikey=1234/, 'apikey is in query params');
like($uri, qr/hash=0d9b0a1ffe216482153a667fb4b68dac/, 'hash is in query params');


