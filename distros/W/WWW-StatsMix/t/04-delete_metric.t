#!perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 2;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->delete_metric() };
like($@, qr/ERROR: Missing the required key metric id./);

eval { $api->delete_metric('x') };
like($@, qr/ERROR: Invalid the required key metric id/);

done_testing();
