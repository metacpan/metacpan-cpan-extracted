#!/usr/env/perl
use strict;
use warnings;
use v5.10;

use Webservice::Judobase;

my $event_id   = $ARGV[0] || 1457;    # Ekaterinburg Grand Slam 2017
my $athlete_id = $ARGV[1] || 2130;    # Papanishvili Amiran

my $srv      = Webservice::Judobase->new;
my $contests = $srv->contests->competition( id => $event_id );

for ( @{$contests} ) {
    next
        unless ( $_->{id_person_white} == $athlete_id
        || $_->{id_person_blue} == $athlete_id );

    my $id = $_->{media};
    $id =~ /yt\*(.*)\*/;

    system("youtube-dl -wc -f mp4 $1") if $id;
}
