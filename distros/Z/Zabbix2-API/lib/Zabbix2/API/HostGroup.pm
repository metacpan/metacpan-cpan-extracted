package Zabbix2::API::HostGroup;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Zabbix2::API::Host;

use Moo;

extends qw/Zabbix2::API::CRUDE/;

has 'hosts' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_hosts');

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{groupid} = $value;
        return $self->data->{groupid};
    } else {
        return $self->data->{groupid};
    }
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix and $suffix =~ m/ids?/) {
        return 'group'.$suffix;
    } elsif ($suffix) {
        return 'hostgroup'.$suffix;
    } else {
        return 'hostgroup';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{name} || '';
}

sub _fetch_hosts {
    my $self = shift;
    my $hosts = $self->{root}->fetch('Host', params => { groupids => [ $self->id ] });
    return $hosts;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::HostGroup -- Zabbix group objects

=head1 SYNOPSIS

  use Zabbix2::API::HostGroup;
  # fetch a single hostgroup by ID
  my $group = $zabbix->fetch_single('HostGroup', params => { groupids => [ 12345 ] });
  # get the hosts which belong to it
  my $hosts = $group->hosts;

=head1 DESCRIPTION

Handles CRUD for Zabbix group objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 hosts

(read-only arrayref of L<Zabbix::API::Host> objects)

This attribute is lazily populated with the hostgroup's hosts from the
server.

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
