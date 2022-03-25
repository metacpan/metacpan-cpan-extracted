use strict;
use warnings;
use v5.10;

# Small script used to create data for blog post:
# https://judometrics.com/2022/03/simple-statistics-about-recent-olympic-judo-tournaments/
#
# Note: you will need to install List::Util and STatistics::Descriptive

use Webservice::Judobase;
use List::Util qw/max min/;
use Statistics::Descriptive;

my $srv = Webservice::Judobase->new;

my %events = (
    2035 => 'Tokyo2020',
    1339 => 'Rio2016',
    1089 => 'London2012',
    2239 => 'Worlds 2021',
    1232 => 'Worlds 2015',
);

my %stats;

for my $event_id ( keys %events ) {
    my $contests = $srv->contests->competition( id => $event_id );
    for my $contest (@$contests) {
        $stats{$event_id}{contests}++;
        $stats{$event_id}{athlete}{ $contest->{id_person_blue} }++;
        $stats{$event_id}{athlete}{ $contest->{id_person_white} }++;

        $stats{$event_id}{golden_score}++ if $contest->{gs};
        $stats{$event_id}{yuko}   += $contest->{yuko};
        $stats{$event_id}{wazari} += $contest->{waza};
        $stats{$event_id}{ippon}  += $contest->{ippon};
        $stats{$event_id}{shido}  += $contest->{penalty};

        my @sections = split( ":", $contest->{duration} );
        my $time = ( $sections[1] * 60 ) + $sections[2];
        push @{ $stats{$event_id}{duration} }, $time;

    }
}

for my $event_id ( keys %events ) {
    say $ogames{$event_id};
    say '---';

    say "Athletes: ", scalar keys %{ $stats{$event_id}{athlete} };
    say "Contests: ", $stats{$event_id}{contests};

    say "Yuko: ",   $stats{$event_id}{yuko};
    say "Wazari: ", $stats{$event_id}{wazari};
    say "Ippon: ",  $stats{$event_id}{ippon};
    say "Shido: ",  $stats{$event_id}{shido};
    say '';
    say "Number of different durations: ",
        scalar @{ $stats{$event_id}{duration} };
    say "Longest contest: ",  max @{ $stats{$event_id}{duration} };
    say "Shortest contest: ", min @{ $stats{$event_id}{duration} };
    say '';
    say 'Shido per contest: ',
        $stats{$event_id}{shido} / $stats{$event_id}{contests};
    say 'Ippon per contest: ',
        $stats{$event_id}{ippon} / $stats{$event_id}{contests};

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data( $stats{$event_id}{duration} );
    my $mean   = $stat->mean();
    my $median = $stat->median();

    my $tm = $stat->trimmed_mean(.25);

    say " Mean: ",         sprintf( "%d.02", $mean );
    say " Median: ",       sprintf( "%d.02", $median );
    say " Trimmed mean: ", sprintf( "%d.02", $tm );

    say '';
}