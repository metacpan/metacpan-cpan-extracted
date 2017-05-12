package VM::EC2::NetworkInterface::Association;

=head1 NAME

VM::EC2::NetworkInterface::Association -- Object representing an association of a network interface with an elastic public IP address

=head1 SYNOPSIS

  use VM::EC2;
  my $ec2 = VM::EC2->new(...);
  my $interface   = $ec2->describe_network_interfaces('eni-12345');
  my $association = $interface->association;
  my $id          = $association->associationId;
  my $public_ip   = $association->ipOwnerId;
  my $address     = $association->address;

=head1 DESCRIPTION

This object provides access to an elastic address association object,
which reversibly associates an elastic public IP address with an
elastic network interface (ENI).

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 associationId
 publicIp
 publicDnsName
 ipOwnerId
 allocationId

In addition, this object supports the following convenience method:

 address() -- Returns the VM::EC2::Address object involved in the
              association.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
public IP address.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self  = shift;
    return qw(associationId publicIp publicDnsName ipOwnerId allocationId);
}

sub address {
    my $self = shift;
    return $self->aws->describe_addresses($self->publicIp);
}

sub short_name { shift->publicIp}

1;

