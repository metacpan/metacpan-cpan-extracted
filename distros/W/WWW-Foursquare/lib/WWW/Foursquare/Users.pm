package WWW::Foursquare::Users;

use strict;
use warnings;

sub new {
    my ($class, $request, $user_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request} = $request;
    $self->{user_id} = $user_id || 'self';

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

# general 
sub leaderboard {
    my ($self, %params) = @_;
    
    my $path = 'users/leaderboard';
    return $self->{request}->GET($path, \%params);
}

sub requests {
    my ($self, %params) = @_;
    
    my $path = 'users/requests';
    return $self->{request}->GET($path, \%params);
}

sub search {
    my ($self, %params) = @_;
    
    my $path = 'users/search';
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub badges {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/badges", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub checkins {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/checkins", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub friends {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/friends", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub lists {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/lists", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub mayorships {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/mayorships", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub photos {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/photos", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

sub venuehistory {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/venuehistory", $self->{user_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub approve {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/approve", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}

sub deny {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/deny", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}

sub request {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/request", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}

sub setpings {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/setpings", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}

sub unfriend {
    my ($self, %params) = @_;

    my $path = sprintf "users/%s/unfriend", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}

sub update {
    my ($self, %params) = @_;

    # change structure for uploading files
    if ($params{photo}) {

        my $path = $params{photo};
        $params{photo} = [ $path ];
    }

    my $path = sprintf "users/%s/update", $self->{user_id};
    return $self->{request}->POST($path, \%params);
}


1;
