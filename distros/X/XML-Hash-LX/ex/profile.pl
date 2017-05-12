#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use XML::Hash::LX;
$ENV{NYTPROF} = 'trace=2:start=no:file='.lib::abs::path('.').'/nytprof.out';

my $xml = do 'xml.pl';
my $hash = xml2hash($xml);

DB::enable_profile();
for (1..100) {
	hash2xml($hash);
}

