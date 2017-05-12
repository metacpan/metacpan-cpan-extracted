#!/usr/bin/perl -T
use strict;
use warnings;
use Data::Dumper;
use lib qw(lib ../lib);
use XML::FeedLite;

my $xfl = XML::FeedLite->new([qw(http://www.atomenabled.org/atom.xml
			         http://rss.slashdot.org/Slashdot/slashdot)]);
my $data = $xfl->entries();

print Dumper($data);
