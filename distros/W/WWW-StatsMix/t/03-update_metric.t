#!perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 8;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->update_metric() };
like($@, qr/ERROR: Missing the required metric id/);

eval { $api->update_metric(1, 'params') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->update_metric('x', { name => 'test' }) };
like($@, qr/ERROR: Invalid metric id/);

eval { $api->update_metric(1, { nme => 'metric name' }) };
like($@, qr/ERROR: Invalid key found in params./);

eval { $api->update_metric(1, { name => undef }) };
like($@, qr/ERROR: Received undefined param: name/);

eval { $api->update_metric(1, { name => 'test', x => 1 }) };
like($@, qr/ERROR: Invalid key found in params./);

eval { $api->update_metric(1, { name => 'test', sharing => 'x' }) };
like($@, qr/ERROR: Invalid data type 'sharing' found/);

eval { $api->update_metric(1, { name => 'test', url => 'x' }) };
like($@, qr/ERROR: Invalid data type 'url' found/);

done_testing();
