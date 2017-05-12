package WWW::Foursquare::Venues;

use strict;
use warnings;

sub new {
    my ($class, $request, $venue_id) = @_;

    my $self = {};
    bless $self, $class;
    $self->{request}  = $request;
    $self->{venue_id} = $venue_id;

    return $self;
}

sub info {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

# general
sub add {
    my ($self, %params) = @_;
    
    my $path = "venues/add";
    return $self->{request}->POST($path, \%params);
}

sub categories {
    my ($self, %params) = @_;

    my $path = "venues/categories";
    return $self->{request}->GET($path, \%params);
}

sub explore {
    my ($self, %params) = @_;
    
    my $path = "venues/explore";
    return $self->{request}->GET($path, \%params);
}

sub managed {
    my ($self, %params) = @_;
    
    my $path = "venues/managed";
    return $self->{request}->GET($path, \%params);
}

sub search {
    my ($self, %params) = @_;
    
    my $path = "venues/managed";
    return $self->{request}->GET($path, \%params);
}

sub suggestcompletion {
    my ($self, %params) = @_;

    my $path = "venues/suggestcompletion";
    return $self->{request}->GET($path, \%params);
}

sub timeseries {
    my ($self, %params) = @_;

    my $path = "venues/timeseries";
    return $self->{request}->GET($path, \%params);
}

sub trending {
    my ($self, %params) = @_;

    my $path = "venues/trending";
    return $self->{request}->GET($path, \%params);
}

# ascpects
sub events {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/events", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub herenow {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/herenow", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub hours {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/hours", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub likes {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/likes", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub links {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/links", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub listed {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/listed", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub menu {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/menu", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub photos {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/photos", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub similar {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/similar", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub stats {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/stats", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

sub tips {
    my ($self, %params) = @_;
 
    my $path = sprintf "venues/%s/tips", $self->{venue_id};
    return $self->{request}->GET($path, \%params);
}

# actions
sub edit {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/edit", $self->{venue_id};
    return $self->{request}->POST($path, \%params);
} 

sub flag {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/flag", $self->{venue_id};
    return $self->{request}->POST($path, \%params);
}   

sub like {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/like", $self->{venue_id};
    return $self->{request}->POST($path, \%params);
}

sub marktodo {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/makrtodo", $self->{venue_id};
    return $self->{request}->POST($path, \%params);
}   

sub proposeedit {
    my ($self, %params) = @_;

    my $path = sprintf "venues/%s/proposeedit", $self->{venue_id};
    return $self->{request}->POST($path, \%params);
}


1;
