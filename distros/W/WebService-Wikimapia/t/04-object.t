#!/usr/bin/perl

use strict; use warnings;
use WebService::Wikimapia;
use Test::More tests => 1;

my $wikimapia = WebService::Wikimapia->new({ api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd' });

eval { $wikimapia->object(); };
like($@, qr/ERROR: Received undefined mandatory param: id/);
