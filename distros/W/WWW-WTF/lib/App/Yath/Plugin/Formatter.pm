package App::Yath::Plugin::Formatter;

use strict;
use warnings;

use parent 'App::Yath::Plugin';

use Data::Dumper;

sub handle_event {
    my $self = shift;
    my ($e, $settings) = @_;

    my $f = $e->facet_data;

    # TODO: collect data in object-property
    #warn Data::Dumper::Dumper($f->{assert}->{details});

    return;
}

sub finish {
    my $self = shift;
    my %params = @_;

    # TODO: create fancy output
}

1;
