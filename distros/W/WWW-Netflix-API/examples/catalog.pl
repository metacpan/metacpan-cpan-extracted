#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;

my %vars = do('./vars.inc');
my $netflix = WWW::Netflix::API->new({
	consumer_key    => $vars{consumer_key},
	consumer_secret => $vars{consumer_secret},
	content_filter  => 'catalog.xml',
});

# NOTE -- There's a much smaller limit (~20x/day) on this request.
# But note that Netflix only updates the catalog daily.
# The catalog is ~300MB of POX.

$netflix->REST->Catalog->Titles->Streaming;
$netflix->Get();

