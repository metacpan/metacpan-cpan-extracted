#!perl

use strict; use warnings;
use WWW::Google::APIDiscovery;
use Test::More;

my ($google);

eval { $google = WWW::Google::APIDiscovery->new; };
plan skip_all => "No internet connection found." if $@;

eval { $google->discover; };
like($@, qr/ERROR: Missing mandatory param: api_id/);

eval { $google->discover('xyz'); };
like($@, qr/ERROR: Unsupported API/);

done_testing();
