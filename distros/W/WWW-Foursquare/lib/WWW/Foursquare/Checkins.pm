package WWW::Foursquare::Checkins;

use strict;
use warnings;

sub new {
    my ($class, $request, $checkin_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{checkin_id} = $checkin_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s", $self->{checkin_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "checkins/add";
    return $self->{request}->POST($path, \%params);
}

sub recent {
    my ($self, %params) = @_;

    my $path = "checkins/recent";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub likes {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/likes", $self->{checkin_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub addcomment {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/addcomment", $self->{checkin_id};
    return $self->{request}->POST($path, \%params);
} 

sub addpost {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/addpost", $self->{checkin_id};
    return $self->{request}->POST($path, \%params);
}   

sub deletecomment {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/deletecomment", $self->{checkin_id};
    return $self->{request}->POST($path, \%params);
}

sub like {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/like", $self->{checkin_id};
    return $self->{request}->POST($path, \%params);
}   

sub reply {
    my ($self, %params) = @_;

    my $path = sprintf "checkins/%s/reply", $self->{checkin_id};
    return $self->{request}->POST($path, \%params);
}


1;
