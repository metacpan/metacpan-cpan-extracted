#!/usr/bin/env perl

use strict;
use warnings;

use WebService::HealthGraph;

my $runkeeper = WebService::HealthGraph->new(
    debug => 1,
    token => $ENV{RUNKEEPER_TOKEN},
);

my $friends = $runkeeper->get( $runkeeper->url_for('team'), { feed => 1 } );

foreach my $item ( @{ $friends->content->{items} } ) {
    my $res = $runkeeper->get( $item->{url} );
}

