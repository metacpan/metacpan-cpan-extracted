#!/usr/bin/perl

use strict; use warnings;
use WebService::Wikimapia;
use Test::More tests => 3;

my $wikimapia = WebService::Wikimapia->new({ api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd' });

eval { $wikimapia->search() };
like($@, qr/ERROR: Missing params list/);

eval { $wikimapia->search('q' => 'Recreation') };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $wikimapia->search({ 'q' => 'Recreation', 'lat' => 37.7887088 }) };
like($@, qr/ERROR: Missing mandatory param: lon/);
