package WWW::Foursquare::Updates;

use strict;
use warnings;

sub new {
    my ($class, $request, $update_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}   = $request;
    $self->{update_id} = $update_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "updates/%s", $self->{update_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub notifications {
    my ($self, %params) = @_;
    
    my $path = "updates/notifications";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub marknotificationsread {
    my ($self, %params) = @_;

    my $path = "updates/marknotificationsread";
    return $self->{request}->POST($path, \%params);
} 


1;
