package WWW::Foursquare::Tips;

use strict;
use warnings;

sub new {
    my ($class, $request, $tip_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{tip_id}   = $tip_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s", $self->{tip_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "tips/add";
    return $self->{request}->POST($path, \%params);
}

sub search {
    my ($self, %params) = @_;

    my $path = "tips/search";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub done {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/done", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
} 

sub likes {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/likes", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}   

sub listed {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/listed", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}

# actions
sub like {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/like", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}

sub markdone {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/markdone", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}

sub marktodo {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/marktodo", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}

sub unmark {
    my ($self, %params) = @_;

    my $path = sprintf "tips/%s/unmark", $self->{tip_id};
    return $self->{request}->POST($path, \%params);
}


1;
