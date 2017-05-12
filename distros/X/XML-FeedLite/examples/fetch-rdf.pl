#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use lib qw(lib ../lib);
use XML::FeedLite::Normalised;

my $feed = XML::FeedLite::Normalised->new('http://search.cpan.org/uploads.rdf');

print Dumper($feed->entries());
