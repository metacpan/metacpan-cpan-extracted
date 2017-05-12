package WWW::Foursquare::Pages;

use strict;
use warnings;

sub new {
    my ($class, $request, $page_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request} = $request;
    $self->{page_id} = $page_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "pages/%s", $self->{page_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub search {
    my ($self, %params) = @_;

    my $path = "pages/search";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub timeseries {
    my ($self, %params) = @_;

    my $path = sprintf "pages/%s/timeseries", $self->{page_id};
    return $self->{request}->POST($path, \%params);
} 

sub venues {
    my ($self, %params) = @_;

    my $path = sprintf "pages/%s/venues", $self->{page_id};
    return $self->{request}->POST($path, \%params);
}   


1;
