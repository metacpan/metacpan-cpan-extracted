#!perl

use strict; use warnings;
use WWW::StatsMix;
use Test::More tests => 11;

my $api_key = 'Your_API_Key';
my $api = WWW::StatsMix->new({ api_key => $api_key });

eval { $api->create_metric() };
like($@, qr/ERROR: Missing params list./);

eval { $api->create_metric('params') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $api->create_metric({ nme => 'metric name', format => 'json' }) };
like($@, qr/ERROR: Missing mandatory param: name/);

eval { $api->create_metric({ name => undef, format => 'json' }) };
like($@, qr/ERROR: Received undefined mandatory param: name/);

eval { $api->create_metric({ name => 'test', x => 1, format => 'json' }) };
like($@, qr/ERROR: Invalid key found in params./);

eval { $api->create_metric({ name => 'test', sharing => 'x', format => 'json' }) };
like($@, qr/ERROR: Invalid data type 'sharing' found/);

eval { $api->create_metric({ name => 'test', url => 'x', format => 'json' }) };
like($@, qr/ERROR: Invalid data type 'url' found/);

eval { $api->create_metric({ name => 'test', sharing => 'public', format => 'json' }) };
like($@, qr/ERROR: Missing key 'url' since 'sharing' is provided/);

eval { $api->create_metric({ name => 'test', sharing => 'public', url => 'x', format => 'json' }) };
like($@, qr/ERROR: Invalid data type 'url' found/);

eval { $api->create_metric({ name => 'test', url => 'http://www.google.com', format => 'json' }) };
like($@, qr/ERROR: Missing key 'sharing' since 'url' is provided/);

eval { $api->create_metric({ name => 'test', url => 'http://www.google.com', sharing => 'x', format => 'json' }) };
like($@, qr/ERROR: Invalid data type 'sharing' found/);

done_testing();
