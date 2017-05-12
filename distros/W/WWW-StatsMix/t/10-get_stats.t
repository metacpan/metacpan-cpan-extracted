#!perl
use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 7;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->get_stats('x') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->get_stats({ limit => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

eval { $api->get_stats({ metric_id => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

eval { $api->get_stats({ start_date => 'x' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->get_stats({ start_date => '2014-09-01' }) };
like($@, qr/ERROR: Missing param key 'end_date'/);

eval { $api->get_stats({ start_date => '2014-09-01', end_date => 'x' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->get_stats({ xyz => 1 }) };
like($@, qr/ERROR: Invalid key found in params/);

done_testing();
