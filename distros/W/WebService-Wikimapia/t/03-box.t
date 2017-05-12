#!/usr/bin/perl

use strict; use warnings;
use WebService::Wikimapia;
use Test::More tests => 3;

my $wikimapia = WebService::Wikimapia->new({ api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd' });

eval { $wikimapia->box(); };
like($@, qr/ERROR: Missing params list/);

eval { $wikimapia->box({ bbox => '1,2,3' }); };
like($@, qr/ERROR: Invalid data type 'bbox'/);

eval { $wikimapia->box({ lon_min => 1 }); };
like($@, qr/ERROR: Missing mandatory param: lat_max/);
