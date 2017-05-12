#!/usr/bin/perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 10;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->update_stat() };
like($@, qr/ERROR: Missing the required key metric id/);

eval { $api->update_stat('x') };
like($@, qr/ERROR: Invalid the required key metric id/);

eval { $api->update_stat(1) };
like($@, qr/ERROR: Missing params list/);

eval { $api->update_stat(1, 'x') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->update_stat(1, [ 'x' ]) };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->update_stat(1, { x => 1 }) };
like($@, qr/ERROR: Missing mandatory param: value/);

eval { $api->update_stat(1, { value => 1.5, id => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

eval { $api->update_stat(1, { value => 1.5, ref_id => undef }) };
like($@, qr/ERROR: Received undefined param: ref_id/);

eval { $api->update_stat(1, { value => 'x' }) };
like($@, qr/ERROR: Invalid data type 'value'/);

eval { $api->update_stat(1, { value => 1.5 }) };
like($@, qr/ERROR: Missing required key id\/ref_id/);

done_testing();
