#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.0303';

use lib qw(../lib lib);
use WWW::CPANRatings::RSS;

my $rate = WWW::CPANRatings::RSS->new;

#  $rate->fetch
#      or die $rate->error;
# 
# print "Got " . @{ $rate->ratings } . " dists\n";

#for ( @{ $rate->ratings } ) {
#    printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
#        @$_{ qw/dist rating creator comment link/ };
#}

print "\n\n\nNew reviews:\n";

$rate->fetch_unique
    or die $rate->error;

for ( @{ $rate->ratings_unique } ) {
    printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
        @$_{ qw/dist rating creator comment link/ };
}
