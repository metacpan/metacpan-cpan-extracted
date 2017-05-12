#!perl

use strict; use warnings;
use WWW::Google::DistanceMatrix;
use Test::More tests => 9;

my $google = WWW::Google::DistanceMatrix->new(api_key => 'API Key');

eval { $google->getDistance; };
like($@, qr{Missing mandatory param: origins/destinations});

eval { $google->getDistance({ o_addr => ['Address 1'] }); };
like($@, qr/Missing mandatory param: destinations/);

eval { $google->getDistance({ o_addr => 'Address 1' }); };
like($@, qr/Missing mandatory param: origins/);

eval { $google->getDistance({ o_latlng => ['-1.50,'] }); };
like($@, qr/Invalid data type 'latlng' found/);

eval { $google->getDistance({ o_latlng => '-1.50,' }); };
like($@, qr/Missing mandatory param: origins/);

eval { $google->getDistance({ d_addr => ['Address 1'] }); };
like($@, qr/Missing mandatory param: origins/);

eval { $google->getDistance({ d_addr => 'Address 1' }); };
like($@, qr/Missing mandatory param: origins/);

eval { $google->getDistance({ d_latlng => ['-1.50,'] }); };
like($@, qr/Missing mandatory param: origins/);

eval { $google->getDistance({ d_latlng => '-1.50,' }); };
like($@, qr/Missing mandatory param: origins/);
