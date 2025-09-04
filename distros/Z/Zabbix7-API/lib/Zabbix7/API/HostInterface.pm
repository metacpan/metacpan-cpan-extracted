package Zabbix7::API::HostInterface;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    INTERFACE_TYPE_UNKNOWN => 0,
    INTERFACE_TYPE_AGENT => 1,
    INTERFACE_TYPE_SNMP => 2,
    INTERFACE_TYPE_IPMI => 3,
    INTERFACE_TYPE_JMX => 4,
    INTERFACE_TYPE_ANY => 255,
};

our @EXPORT_OK = qw/
    INTERFACE_TYPE_UNKNOWN
    INTERFACE_TYPE_AGENT
    INTERFACE_TYPE_SNMP
    INTERFACE_TYPE_IPMI
    INTERFACE_TYPE_JMX
    INTERFACE_TYPE_ANY
/;

our %EXPORT_TAGS = (
    interface_types => [
        qw/INTERFACE_TYPE_UNKNOWN
           INTERFACE_TYPE_AGENT
           INTERFACE_TYPE_SNMP
           INTERFACE_TYPE_IPMI
           INTERFACE_TYPE_JMX
           INTERFACE_TYPE_ANY/
    ],
);

has 'host' => (is => 'ro', lazy => 1, builder => '_fetch_host');

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{interfaceid} = $value;
        return $self->data->{interfaceid};
    }
    return $self->data->{interfaceid};
}

sub _readonly_properties {
    return {
        interfaceid => 1,
        hostid => 1, # Read-only in Zabbix 7.0
        flags => 1,  # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix and $suffix =~ m/ids?/) {
        return 'interface' . $suffix;
    } elsif ($suffix) {
        return 'hostinterface' . $suffix;
    }
    return 'hostinterface';
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{useip} == 0 ? $self->data->{dns} : $self->data->{ip};
    Log::Any->get_logger->debug("Generated name for interface ID: " . ($self->id // 'new') . ": $name");
    return $name || '';
}

sub _fetch_host {
    my $self = shift;
    my $host = $self->{root}->fetch_single('Host', params => { hostids => [ $self->data->{hostid} ] });
    Log::Any->get_logger->debug("Fetched host for interface ID: " . ($self->id // 'new') . ", hostid: " . ($self->data->{hostid} // 'unknown'));
    return $host;
}

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{hostid}; # hostid is read-only
    delete $self->data->{flags};  # flags is read-only
    Log::Any->get_logger->debug("Preparing to update interface ID: " . ($self->id // 'new'));
};

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{interfaceid}; # Ensure interfaceid is not sent
    delete $self->data->{flags};      # flags is read-only
    Log::Any->get_logger->debug("Preparing to create interface for hostid: " . ($self->data->{hostid} // 'unknown'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::HostInterface -- Zabbix host interface objects

=head1 SYNOPSIS

  # create it with the host
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
  
  # create it later
  my $new_interface = Zabbix7::API::HostInterface->new(
      root => $zabbix,
      data => {
          dns => 'some other hostname',
          ip => '',
          useip => 0,
          main => 1,
          port => 10001,
          type => Zabbix7::API::HostInterface::INTERFACE_TYPE_AGENT,
          hostid => $new_host->id
      });
  $new_interface->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix interface objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

L<Zabbix7::API::HostInterface> objects will be automatically created
from a L<Zabbix7::API::Host> object's properties whenever it is pulled
from the server.  Conversely, if you add interfaces manually to a
L<Zabbix7::API::Host> object, the L<Zabbix7::API::HostInterface>
objects will be automatically turned into properties just before a
call to C<create> or C<update>, causing the relevant host interface
objects to be created or updated on the server.

=head1 ATTRIBUTES

=head2 host

(read-only L<Zabbix7::API::Host> object)

This attribute is lazily populated with the interface's host from the
server.

=head1 EXPORTS

Some constants:

  INTERFACE_TYPE_UNKNOWN
  INTERFACE_TYPE_AGENT
  INTERFACE_TYPE_SNMP
  INTERFACE_TYPE_IPMI
  INTERFACE_TYPE_JMX
  INTERFACE_TYPE_ANY

They are not exported by default, only on request; or you could import
the C<:interface_types> tag.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>, L<Zabbix7::API::Host>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
