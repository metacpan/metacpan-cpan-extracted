package WWW::Foursquare::Campaigns;

use strict;
use warnings;

sub new {
    my ($class, $request, $campaign_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}     = $request;
    $self->{campaign_id} = $campaign_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "campaigns/%s", $self->{campaign_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "campaigns/add";
    return $self->{request}->POST($path, \%params);
}

sub list {
    my ($self, %params) = @_;

    my $path = "campaigns/list";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub timeseries {
    my ($self, %params) = @_;

    my $path = sprintf "campaigns/%s/timeseries", $self->{campaign_id};
    return $self->{request}->GET($path, \%params);
} 

# actions
sub delete {
    my ($self, %params) = @_;

    my $path = sprintf "campaigns/%s/delete", $self->{campaign_id};
    return $self->{request}->POST($path, \%params);
}

sub end {
    my ($self, %params) = @_;

    my $path = sprintf "campaigns/%s/end", $self->{campaign_id};
    return $self->{request}->POST($path, \%params);
}

sub start {
    my ($self, %params) = @_;

    my $path = sprintf "campaigns/%s/start", $self->{campaign_id};
    return $self->{request}->POST($path, \%params);
}


1;
