#!perl
use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 9;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->delete_stat() };
like($@, qr/ERROR: Missing the required key metric id./);

eval { $api->delete_stat('x') };
like($@, qr/ERROR: Invalid the required key metric id/);

eval { $api->delete_stat(1) };
like($@, qr/ERROR: Missing params list/);

eval { $api->delete_stat(1, 'x') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->delete_stat(1, [ 'x' ]) };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->delete_stat(1, { x => 1 }) };
like($@, qr/ERROR: Invalid key found in params/);

eval { $api->delete_stat(1, { id => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

eval { $api->delete_stat(1, { ref_id => undef }) };
like($@, qr/ERROR: Received undefined param: ref_id/);

eval { $api->delete_stat(1, { }) };
like($@, qr/ERROR: Missing required key id\/ref_id/);

done_testing();
