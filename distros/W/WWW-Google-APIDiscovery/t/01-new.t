#!perl

use strict; use warnings;
use WWW::Google::APIDiscovery;
use Test::More tests => 1;

eval { WWW::Google::APIDiscovery->new('test'); };
like($@, qr/ERROR: No parameters required for constructor/);
