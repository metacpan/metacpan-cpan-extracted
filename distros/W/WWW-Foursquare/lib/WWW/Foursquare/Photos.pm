package WWW::Foursquare::Photos;

use strict;
use warnings;

sub new {
    my ($class, $request, $photo_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}   = $request;
    $self->{photo_id}  = $photo_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "photos/%s", $self->{photo_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "photos/add";
    return $self->{request}->POST($path, \%params);
}


1;
