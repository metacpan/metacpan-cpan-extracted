package WWW::Foursquare::Venuegroups;

use strict;
use warnings;

sub new {
    my ($class, $request, $group_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{group_id} = $group_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s", $self->{group_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "venuegroups/add";
    return $self->{request}->POST($path, \%params);
}

sub delete {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/delete", $self->{group_id};
    return $self->{request}->POST($path, \%params);
}

sub list {
    my ($self, %params) = @_;
    
    my $path = "venuegroups/list";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub timeseries {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/timeseries", $self->{group_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub addvenue {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/addvenue", $self->{group_id};
    return $self->{request}->POST($path, \%params);
} 

sub campaigns {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/campaigns", $self->{group_id};
    return $self->{request}->POST($path, \%params);
}   

sub edit {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/edit", $self->{group_id};
    return $self->{request}->POST($path, \%params);
}

sub removevenue {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/removevenue", $self->{group_id};
    return $self->{request}->POST($path, \%params);
}   

sub update {
    my ($self, %params) = @_;

    my $path = sprintf "venuegroups/%s/update", $self->{group_id};
    return $self->{request}->POST($path, \%params);
}


1;
