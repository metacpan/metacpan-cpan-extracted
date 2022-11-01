#!/usr/env/perl

use strict;
use warnings;
use v5.10;

$|++;

use Webservice::Judobase;
use Text::CSV_XS qw( csv );

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $srv = Webservice::Judobase->new;

# So we want to get all the contests for all events.
# Transform into a CSV, with these fields:
#[ Date; Event; Athlete 1; Country 1; Athlete 2; Country 2; Score Athlete 1; Score Athlete 2; Contest Time; Round ]

my @data;

# loop through events:
#        1039 to 1460
#  Sofia 2009 to Hohhot 2017
my $events = $srv->general->competitions;

for my $competition ( sort @{$events} ) {
    print ".";
    my $event_id = $competition->{id_competition};
    my $event    = $srv->general->competition( id => $event_id );

    next unless defined $event;
    next unless ref $event eq 'HASH';
    next unless $event && $event->{ages} && $event->{ages} eq 'Seniors';

    my $contests = $srv->contests->competition( id => $event_id );

    next unless scalar @{$contests};

    for ( @{$contests} ) {
        my %contest;
        $contest{date}             = $_->{date_raw};
        $contest{category}         = $_->{weight};
        $contest{athlete_1_ippon}  = $_->{ippon_w};
        $contest{athlete_1_shido}  = $_->{penalty_w};
        $contest{athlete_1_wazari} = $_->{waza_w};
        $contest{athlete_1_yuko}   = $_->{yuko_w};
        $contest{athlete_1}        = $_->{person_white};
        $contest{athlete_2_ippon}  = $_->{ippon_b};
        $contest{athlete_2_shido}  = $_->{penalty_b};
        $contest{athlete_2_wazari} = $_->{waza_b};
        $contest{athlete_2_yuko}   = $_->{yuko_b};
        $contest{athlete_2}        = $_->{person_blue};
        $contest{country_1}        = $_->{country_white};
        $contest{country_2}        = $_->{country_blue};
        $contest{event}            = $_->{competition_name};
        $contest{round}            = $_->{round_name};
        $contest{time}             = $_->{duration};
        $contest{contest_code}     = $_->{contest_code_long};

        if ( $_->{id_winner} == $_->{id_person_white} ) {
            $contest{winner} = $_->{person_white};
            $contest{loser}  = $_->{person_blue};
        }
        else {
            $contest{loser}  = $_->{person_white};
            $contest{winner} = $_->{person_blue};
        }

        push @data, \%contest;
    }

}

#say Dumper \@data;
my $err = csv( in => \@data, out => "summary_data.csv", encoding => "UTF-8" );

warn $err if $err != 1;

1;
