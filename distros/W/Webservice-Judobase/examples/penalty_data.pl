#!/usr/env/perl
use strict;
use warnings;
use v5.10;

# This is an example script to identify events where a bug
# affected Judobase in that no player in blue had penalties
# recorded against them.
# First identified by Bob Challis looking at 2014 Senior WC

use Webservice::Judobase;

my $srv = Webservice::Judobase->new;

use Data::Dumper;
my %annual_data;

# loop through events:
#        1039 to 1460
#  Sofia 2009 to Hohhot 2017
for my $event_id ( 1039 .. 1460 ) {
    my $event = $srv->general->competition( id => $event_id );
    next unless defined $event;

    my $contests = $srv->contests->competition( id => $event_id );
    next unless scalar @{$contests};

    my %data = ( white => 0, blue => 0 );

    for ( @{$contests} ) {
    $annual_data{$event->{year}}{contests}++;
    $annual_data{$event->{year}}{penalties} += $_->{penalty_w} + $_->{penalty_b};
        $data{white} += $_->{penalty_w} if $_->{penalty_w};
        $data{blue}  += $_->{penalty_b} if $_->{penalty_b};
    }

    say join ',', $event->{title} // '',
        $event->{year} // '',
        $event->{country} // '',
    $data{white},
    $data{blue};
}

$Data::Dumper::Sortkeys=1;
say Dumper \%annual_data;

1;
