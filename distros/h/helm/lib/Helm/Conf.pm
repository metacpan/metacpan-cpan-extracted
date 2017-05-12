package Helm::Conf;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Helm::Server;

has servers => (is => 'ro', writer => '_servers', isa => 'ArrayRef[Helm::Server]');

sub get_servers_by_roles {
    my ($self, $roles, $exclude) = @_;
    $exclude ||= [];
    return
      grep { $_->has_role(@$roles) && (!@$exclude || !$_->has_role(@$exclude)) } @{$self->servers};
}

sub get_server_by_abbrev {
    my ($self, $name, $helm) = @_;
    my $name_length = length $name;
    my $match;
    foreach my $server (@{$self->servers}) {
        if ($server->name_length >= $name_length) {
            if (substr($server->name, 0, $name_length) eq $name) {
                if (!$match || $name eq $server->name) {
                    $match = $server;
                } else {
                    $helm->die("Server abbreviation $name is ambiguous. Looks like $match and " . $self->name);
                }
            }
        }
    }
    return $match;
}

sub get_all_server_names {
    my $self = shift;
    return map { $_->name } @{$self->servers};
}


__PACKAGE__->meta->make_immutable;

1;
