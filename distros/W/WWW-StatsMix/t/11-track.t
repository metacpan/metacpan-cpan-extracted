#!perl
use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 8;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->track() };
like($@, qr/ERROR: Missing params list/);

eval { $api->track('x') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->track({ xyz => 1 }) };
like($@, qr/ERROR: Missing mandatory param: name/);

eval { $api->track({ name => undef }) };
like($@, qr/ERROR: Received undefined mandatory param: name/);

eval { $api->track({ name => 'x', xyz => 1 }) };
like($@, qr/ERROR: Invalid key found in params/);

eval { $api->track({ name => 'x', value => 'x' }) };
like($@, qr/ERROR: Invalid data type 'value'/);

eval { $api->track({ name => 'x', generated_at => 'x' }) };
like($@, qr/ERROR: Invalid data of type 'date'/);

eval { $api->track({ name => 'x', profile_id => 'x' }) };
like($@, qr/ERROR: Invalid NUM data type/);

done_testing();
