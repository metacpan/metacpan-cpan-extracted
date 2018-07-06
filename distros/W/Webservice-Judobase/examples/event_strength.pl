#!/usr/env/perl
use strict;
use warnings;
use v5.10;

# This example script was developed with Gaert Claes to support his
# PHD studies researching the results of IJF elite competitions

use Webservice::Judobase;

my $srv = Webservice::Judobase->new;
my $event_id = $ARGV[0] || 1455;    # 2017 Europeans

my $event = $srv->general->competition( id => $event_id );
my $contests = $srv->contests->competition( id => $event_id );

my $base_url = 'http://data.judobase.org/api/get_json?';

my %categories;

my $header = join ',',
    qw/ category
    round
    winner
    ijf_id_winner
    dob_winner
    country_winner
    wrl_points_winner
    belt_winner
    loser
    ijf_id_loser
    dob_loser
    country_loser
    wrl_points_loser
    belt_loser/;
say $header;

for ( @{$contests} ) {
    $categories{ $_->{weight} }{ $_->{id_ijf_blue} }++;
    $categories{ $_->{weight} }{ $_->{id_ijf_white} }++;

    next
        unless $_->{round_name} eq 'Final'
        || $_->{round_name} eq 'Bronze'
        || $_->{round_name} eq 'Semi-Final';

    my $athlete_blue  = $srv->competitor->info( id => $_->{id_person_blue} );
    my $athlete_white = $srv->competitor->info( id => $_->{id_person_white} );

    my $wrl_blue = $srv->competitor->wrl_current( id => $_->{id_person_blue} )
        ->{points};
    my $wrl_white
        = $srv->competitor->wrl_current( id => $_->{id_person_white} )
        ->{points};

    my @facts;
    push @facts, $_->{weight};
    push @facts, $_->{round_name};

    if ( $_->{id_winner} == $_->{id_person_blue} ) {
        push @facts, $_->{person_blue};
        push @facts, $_->{id_ijf_blue};
        push @facts, $athlete_blue->{birth_date};
        push @facts, $wrl_blue;
        push @facts, $_->{country_blue};
        push @facts, 'Blue';
        push @facts, $_->{person_white};
        push @facts, $_->{id_ijf_white};
        push @facts, $athlete_white->{birth_date};
        push @facts, $wrl_white;
        push @facts, $_->{country_white};
        push @facts, 'White';
    }
    else {
        push @facts, $_->{person_white};
        push @facts, $_->{id_ijf_white};
        push @facts, $athlete_white->{birth_date};
        push @facts, $wrl_white;
        push @facts, $_->{country_white};
        push @facts, 'White';
        push @facts, $_->{person_blue};
        push @facts, $_->{id_ijf_blue};
        push @facts, $athlete_blue->{birth_date};
        push @facts, $wrl_blue;
        push @facts, $_->{country_blue};
        push @facts, 'Blue';
    }

    say join ',', @facts;
}

say '';

for ( sort keys %categories ) {
    my %athletes = %{ $categories{$_} };
    say $_ . ',' . scalar keys %athletes;
}

say $event->{title};
say $event->{year};
say $event->{country};

1;
