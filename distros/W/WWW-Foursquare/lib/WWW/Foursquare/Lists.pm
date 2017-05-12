package WWW::Foursquare::Lists;

use strict;
use warnings;

sub new {
    my ($class, $request, $list_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{list_id}   = $list_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s", $self->{list_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "lists/add";
    return $self->{request}->POST($path, \%params);
}

# ascpects
sub followers {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/followers", $self->{list_id};
    return $self->{request}->POST($path, \%params);
} 

sub suggestphoto {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/suggestphoto", $self->{list_id};
    return $self->{request}->GET($path, \%params);
}   

sub suggesttip {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/suggesttip", $self->{list_id};
    return $self->{request}->GET($path, \%params);
}

sub suggestvenues {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/suggestvenues", $self->{list_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub additem {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/additem", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub deleteitem {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/deleteitem", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub moveitem {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/moveitem", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub share {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/share", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub unfollow {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/unfollow", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub update {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/update", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}

sub updateitem {
    my ($self, %params) = @_;

    my $path = sprintf "lists/%s/updateitem", $self->{list_id};
    return $self->{request}->POST($path, \%params);
}


1;
