package WWW::Foursquare::Pageupdates;

use strict;
use warnings;

sub new {
    my ($class, $request, $update_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request} = $request;
    $self->{update_id} = $update_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "pageupdates/%s", $self->{update_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;

    my $path = "pageupdates/add";
    return $self->{request}->POST($path, \%params);
}

sub list {
    my ($self, %params) = @_;

    my $path = "pageupdates/list";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub delete {
    my ($self, %params) = @_;

    my $path = sprintf "pageupdates/%s/delete", $self->{update_id};
    return $self->{request}->POST($path, \%params);
} 

sub like {
    my ($self, %params) = @_;

    my $path = sprintf "pageupdates/%s/like", $self->{update_id};
    return $self->{request}->POST($path, \%params);
}   


1;
