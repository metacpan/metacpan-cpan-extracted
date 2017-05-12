package WWW::Foursquare::Settings;

use strict;
use warnings;

sub new {
    my ($class, $request, $setting_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}    = $request;
    $self->{setting_id} = $setting_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "settings/%s", $self->{setting_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub all {
    my ($self, %params) = @_;
    
    my $path = "settings/all";
    return $self->{request}->GET($path, \%params);
}

# actions
sub set {
    my ($self, %params) = @_;

    my $path = sprintf "settings/%s/set", $self->{setting_id};
    return $self->{request}->GET($path, \%params);
}


1;
