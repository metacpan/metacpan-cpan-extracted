#!/usr/local/bin/perl

# Example script making use of URI to process URIs with the 
# 'urn' scheme

use URI::crid;

my @objects = (
	URI->new('urn:mediastore:timeline:123'),
	URI->new('/home/project/applications/data/foo/junk/123.txt'),
	URI->new('crid://bbc.co.uk/b1234567'),
);

foreach my $o (@objects) {
	print "$o$/";
	foreach my $t (qw(scheme path nid nss authority data)) {
		print sprintf("\t%s: %s $/", $t, eval('$o->'.$t));
	}
}
