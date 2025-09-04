package Zabbix7::API::Host;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Zabbix7::API::CRUDE/;
use Zabbix7::API::HostInterface;
use Zabbix7::API::Template;

has 'items' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_items');
has 'interfaces' => (is => 'rw');
has 'hostgroups' => (is => 'ro',
                     lazy => 1,
                     builder => '_fetch_hostgroups');
has 'templates' => (is => 'ro',
                    lazy => 1,
                    builder => '_fetch_templates');
has 'graphs' => (is => 'ro',
                 lazy => 1,
                 builder => '_fetch_graphs');

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{hostid} = $value;
        return $self->data->{hostid};
    } else {
        return $self->data->{hostid};
    }
}

sub _readonly_properties {
    return {
        hostid => 1,
        available => 1,
        auto_compress => 1,
        disable_until => 1,
        error => 1,
        errors_from => 1,
        flags => 1,
        ipmi_available => 1,
        ipmi_disable_until => 1,
        ipmi_error => 1,
        ipmi_errors_from => 1,
        jmx_available => 1,
        jmx_error => 1,
        jmx_errors_from => 1,
        maintenance_from => 1,
        maintenance_status => 1,
        maintenance_type => 1,
        maintenanceid => 1,
        snmp_available => 1,
        snmp_disable_until => 1,
        snmp_error => 1,
        snmp_errors_from => 1,
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'host'.$suffix;
    } else {
        return 'host';
    }
}

sub _extension {
    return (
        output => 'extend',
        selectMacros => ['macro', 'value', 'description'], # Updated for Zabbix 7.0
        selectInterfaces => 'extend',
        selectGroups => 'extend', # Added for hostgroups
        selectTemplates => 'extend' # Added for templates
    );
}

sub name {
    my $self = shift;
    return $self->data->{host} || '???';
}

sub _fetch_items {
    my $self = shift;
    my $items = $self->{root}->fetch('Item', params => { hostids => [ $self->data->{hostid} ] });
    return $items;
}

sub _fetch_hostgroups {
    my $self = shift;
    my $items = $self->{root}->fetch('HostGroup', params => { hostids => [ $self->data->{hostid} ] });
    return $items;
}

sub _fetch_templates {
    my $self = shift;
    my $items = $self->{root}->fetch('Template', params => { hostids => [ $self->data->{hostid} ] });
    return $items;
}

sub _fetch_graphs {
    my $self = shift;
    my $graphs = $self->{root}->fetch('Graph', params => { hostids => [ $self->data->{hostid} ] });
    return $graphs;
}

sub _map_interfaces_to_property {
    my ($self) = @_;
    $self->data->{interfaces} = [ map { $_->data } @{$self->interfaces} ];
    return;
}

sub _map_property_to_interfaces {
    my ($self) = @_;
    my @interfaces = map { Zabbix7::API::HostInterface->new(root => $self->root,
                                                            data => $_) } @{$self->data->{interfaces}};
    $self->interfaces(\@interfaces);
    return;
}

before 'create' => \&_map_interfaces_to_property;
before 'update' => \&_map_interfaces_to_property;
after 'pull' => \&_map_property_to_interfaces;
around 'new' => sub {
    my ($orig, @rest) = @_;
    my $host = $orig->(@rest);
    $host->_map_property_to_interfaces;
    return $host;
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Host -- Zabbix host objects

=head1 SYNOPSIS

  use Zabbix7::API::Host;
  # fetch a single host by ID
  my $host = $zabbix->fetch_single('Host', params => { hostids => [ 10105 ] });
  
  # and delete it
  $host->delete;
  
  # helpers -- these all fire an API call
  my $items = $host->items;
  my $hostgroups = $host->hostgroups;
  my $graphs = $host->graphs;
  my $templates = $host->templates;
  
  # this one doesn't
  my $interfaces = $host->interfaces;
  
  # create a new host and its interfaces in one fell swoop
  my $new_host = Zabbix7::API::Host->new(
      root => $zabbix,
      data => {
          host => 'the internal zabbix hostname',
          name => 'the name displayed in most places',
          groups => [ { groupid => 4 } ],
          interfaces => [
              { dns => 'some hostname',
                ip => '',
                useip => 0,
                main => 1,
                port => 10000,
                type => Zabbix7::API::HostInterface::INTERFACE_TYPE_AGENT,
              } ] });
  $new_host->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix host objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 graphs

(read-only arrayref of L<Zabbix7::API::Graph> objects)

This attribute is lazily populated with the host's graphs from the
server.

=head2 hostgroups

(read-only arrayref of L<Zabbix7::API::HostGroup> objects)

This attribute is lazily populated with the host's hostgroups from the
server.

=head2 interfaces

(read-write arrayref of L<Zabbix7::API::HostInterface> instances)

This attribute is populated automatically from the "interfaces" server
property when the Perl object is updated (i.e. when the C<pull> method
is called).

Likewise, it is automatically used to populate the "interfaces"
property before either C<create> or C<update> are called.

Note that "interfaces" is a required property as far as the server is
concerned, so you must define it one way or another.

You can add interfaces by pushing new L<Zabbix7::API::HostInterface>
objects onto this arrayref and then calling C<< $host->update >>, or
by instantiating interface objects with the C<hostid> property set and
calling C<< $interface->create >>.

=head2 items

(read-only arrayref of L<Zabbix7::API::Item> objects)

This attribute is lazily populated with the host's items from the
server.

=head2 templates

(read-write arrayref of L<Zabbix7::API::Template> instances)

This attribute is lazily-populated with the host's templates from the
server.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
