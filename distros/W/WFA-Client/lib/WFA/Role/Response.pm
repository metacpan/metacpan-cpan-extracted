package WFA::Role::Response;

use 5.008;
use strict;
use warnings;
use Moo::Role;

has client => (
    is       => 'ro',
    required =>    1,
);

has response => (
    is       => 'rw',
    required =>    1,
);

sub actions {
    my ($self) = @_;
    my @actions = sort keys %{ $self->response()->{'atom:link'} };
    return @actions;
};

sub url_for_action {
    my ($self, $action) = @_;
    return $self->response()->{'atom:link'}->{$action}->{href};
}

1;
