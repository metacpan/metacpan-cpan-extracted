package WWW::Foursquare::Events;

use strict;
use warnings;

sub new {
    my ($class, $request, $event_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{event_id} = $event_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "events/%s", $self->{event_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub categories {
    my ($self, %params) = @_;
    
    my $path = "events/categories";
    return $self->{request}->GET($path, \%params);
}

sub search {
    my ($self, %params) = @_;

    my $path = "events/search";
    return $self->{request}->GET($path, \%params);
}


1;
