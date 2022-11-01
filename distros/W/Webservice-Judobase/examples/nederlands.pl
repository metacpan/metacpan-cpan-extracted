use strict;
use warnings;
use v5.10;

# Demo script written for the Perl Conference in Amsterdam

use Webservice::Judobase;

my $srv      = Webservice::Judobase->new;
my $event_id = $ARGV[0] || 1455;            # 2017 European Championships

my $contests = $srv->contests->competition( id => $event_id );

my %athletes;

say 'Team Nederlands';
say '---------------';

for (@$contests) {

    $athletes{ $_->{person_white} }++
        if $_->{country_short_white} eq 'NED';
    $athletes{ $_->{person_blue} }++
        if $_->{country_short_blue} eq 'NED';
}

say $_ for sort keys %athletes;

