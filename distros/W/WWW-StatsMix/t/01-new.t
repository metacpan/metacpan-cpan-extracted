#!perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 5;

my $api_key = 'Your_API_Key';

eval { WWW::StatsMix->new(); };
like($@, qr/Missing required arguments: api_key/);

eval { WWW::StatsMix->new($api_key); };
like($@, qr/Single parameters to new\(\) must be a HASH ref data/);

eval { WWW::StatsMix->new(x => $api_key); };
like($@, qr/Missing required arguments: api_key/);

eval { WWW::StatsMix->new({ x => $api_key }); };
like($@, qr/Missing required arguments: api_key/);

ok(WWW::StatsMix->new({ api_key => $api_key }));

done_testing();
