#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use DateTime ();
use URI::FromHash qw( uri );
use WebService::HealthGraph ();

my $runkeeper = WebService::HealthGraph->new(
    auto_pagination => 0,
    debug           => 0,
    token           => $ENV{HEALTHGRAPH_TOKEN},
);

# Fetch an activities feed
my $cutoff = DateTime->now->subtract( days => 28 );

my $uri = $runkeeper->uri_for(
    'fitness_activities',
    { noEarlierThan => $cutoff->ymd, pageSize => 20, },
);

my $feed = $runkeeper->get( $uri, { feed => 1 } );

# Print the first Running activity, if any.
while ( my $item = $feed->next ) {
    if ( $item->{type} eq 'Running' ) {
        my $activity = $runkeeper->get( $item->{uri} );
        p $activity->content;
        last;
    }
}
