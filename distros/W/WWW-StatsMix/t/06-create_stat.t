#!/usr/bin/perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 12;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->create_stat() };
like($@, qr/ERROR: Missing params list./);

eval { $api->create_stat('x') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->create_stat({ x => 1 }) };
like($@, qr/ERROR: Missing mandatory param: metric_id/);

eval { $api->create_stat({ metric_id => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

eval { $api->create_stat({ metric_id => 1 }) };
like($@, qr/ERROR: Missing mandatory param: value/);

eval { $api->create_stat({ metric_id => 1, value => 'x' }) };
like($@, qr/ERROR: Invalid data type 'value'/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, xyz => 1 }) };
like($@, qr/ERROR: Invalid key found in params/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, generated_at => 'x' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, generated_at => '2000-14-01' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, generated_at => '2000/14/01' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, meta => 'x' }) };
like($@, qr/ERROR: Invalid data format for key 'meta'/);

eval { $api->create_stat({ metric_id => 1, value => 1.5, meta => [ 'x' ] }) };
like($@, qr/ERROR: Invalid data format for key 'meta'/);

done_testing();
