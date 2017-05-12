#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use DateTime ();
use URI::FromHash qw( uri );
use WebService::HealthGraph ();

my $runkeeper = WebService::HealthGraph->new(
    debug => 1,
    token => $ENV{HEALTHGRAPH_TOKEN},
);

my $user = $runkeeper->user;
p $user->content;

# Fetch a weight feed
my $cutoff = DateTime->now->subtract( days => 28 );

my $uri = $runkeeper->uri_for(
    'weight',
    { noEarlierThan => $cutoff->ymd, pageSize => 10, },
);

my $feed = $runkeeper->get( $uri, { feed => 1 } );

my $count;
while ( my $item = $feed->next ) {
    ++$count;
    last if $count == 20;
}
