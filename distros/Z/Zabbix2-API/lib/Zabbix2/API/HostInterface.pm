package Zabbix2::API::HostInterface;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Exporter Zabbix2::API::CRUDE/;

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

has 'host' => (is => 'ro',
               lazy => 1,
               builder => '_fetch_host');

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        if ($suffix =~ m/ids?/) {
            return 'interface'.$suffix;
        }
        return 'hostinterface'.$suffix;
    } else {
        return 'hostinterface';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{useip} == 0 ? $self->data->{dns} : $self->data->{ip};
}

sub _fetch_host {
    my $self = shift;
    my $host = $self->{root}->fetch_single('Host', params => { hostids => [ $self->data->{hostid} ] });
    return $host;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::HostInterface -- Zabbix host interface objects

=head1 SYNOPSIS

  # create it with the host
  my $new_host = Zabbix2::API::Host->new(
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
                type => Zabbix2::API::HostInterface::INTERFACE_TYPE_AGENT,
              } ] });
  $new_host->create;
  
  # create it later
  my $new_interface = Zabbix2::API::HostInterface->new(
      root => $zabbix,
      data => {
          dns => 'some other hostname',
          ip => '',
          useip => 0,
          main => 1,
          port => 10001,
          type => Zabbix2::API::HostInterface::INTERFACE_TYPE_AGENT,
          hostid => $new_host->id
      });
  $new_interface->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix interface objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

L<Zabbix2::API::HostInterface> objects will be automatically created
from a L<Zabbix2::API::Host> object's properties whenever it is pulled
from the server.  Conversely, if you add interfaces manually to a
L<Zabbix2::API::Host> object, the L<Zabbix2::API::HostInterface>
objects will be automatically turned into properties just before a
call to C<create> or C<update>, causing the relevant host interface
objects to be created or updated on the server.

=head1 ATTRIBUTES

=head2 host

(read-only L<Zabbix2::API::Host> object)

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

L<Zabbix2::API::CRUDE>, L<Zabbix2::API::Host>

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Fabrice Gabolde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
