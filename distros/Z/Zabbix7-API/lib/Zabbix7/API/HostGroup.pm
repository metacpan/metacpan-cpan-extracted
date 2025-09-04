package Zabbix7::API::HostGroup;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Zabbix7::API::Host;

use Moo;

extends qw/Zabbix7::API::CRUDE/;

has 'hosts' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_hosts');

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{groupid} = $value;
        return $self->data->{groupid};
    }
    return $self->data->{groupid};
}

sub _readonly_properties {
    return {
        groupid => 1,
        flags => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix and $suffix =~ m/ids?/) {
        return 'group' . $suffix;
    } elsif ($suffix) {
        return 'hostgroup' . $suffix;
    }
    return 'hostgroup';
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    return $self->data->{name} || '';
}

sub _fetch_hosts {
    my $self = shift;
    my $hosts = $self->{root}->fetch('Host', params => { groupids => [ $self->id ] });
    Log::Any->get_logger->debug("Fetched " . scalar @$hosts . " hosts for hostgroup ID: " . $self->id);
    return $hosts;
}

1;
__END__
=pod

=head1 NAME

Zabbix7::API::HostGroup -- Zabbix group objects

=head1 SYNOPSIS

  use Zabbix7::API::HostGroup;
  # fetch a single hostgroup by ID
  my $group = $zabbix->fetch_single('HostGroup', params => { groupids => [ 12345 ] });
  # get the hosts which belong to it
  my $hosts = $group->hosts;

=head1 DESCRIPTION

Handles CRUD for Zabbix group objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 hosts

(read-only arrayref of L<Zabbix::API::Host> objects)

This attribute is lazily populated with the hostgroup's hosts from the
server.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH


This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
