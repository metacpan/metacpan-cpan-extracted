package WWW::Foursquare::Specials;

use strict;
use warnings;

sub new {
    my ($class, $request, $special_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}    = $request;
    $self->{special_id} = $special_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "specials/%s", $self->{special_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "specials/add";
    return $self->{request}->POST($path, \%params);
}

sub list {
    my ($self, %params) = @_;

    my $path = "specials/list";
    return $self->{request}->GET($path, \%params);
}

sub search {
    my ($self, %params) = @_;

    my $path = "specials/search";
    return $self->{request}->GET($path, \%params);
}

# aspects
sub configuration {
    my ($self, %params) = @_;

    my $path = sprintf "specials/%s/configuration", $self->{special_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub flag {
    my ($self, %params) = @_;

    my $path = sprintf "specials/%s/flag", $self->{special_id};
    return $self->{request}->POST($path, \%params);
}

sub retire {
    my ($self, %params) = @_;

    my $path = sprintf "specials/%s/retire", $self->{special_id};
    return $self->{request}->POST($path, \%params);
}


1;
