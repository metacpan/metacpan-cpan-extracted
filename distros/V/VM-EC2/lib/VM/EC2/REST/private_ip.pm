package VM::EC2::REST::private_ip;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    AssignPrivateIpAddresses          => 'boolean',
    UnassignPrivateIpAddresses        => 'boolean',
    );

=head1 NAME VM::EC2::REST::private_ip

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods allow you to control private IP addresses associated
with instances running in a VPC.

=head2 $result = $ec2->assign_private_ip_addresses(%args)

Assign one or more secondary private IP addresses to a network
interface. You can either set the addresses explicitly, or provide a
count of secondary addresses, and let Amazon select them for you.

Required arguments:

 -network_interface_id    The network interface to which the IP address(es)
                          will be assigned.

 -private_ip_address      One or more secondary IP addresses, as a scalar string
 -private_ip_addresses    or array reference. (The two arguments are equivalent).

Optional arguments:

 -allow_reassignment      If true, allow assignment of an IP address is already in
                          use by another network interface or instance.

The following are valid arguments to -private_ip_address:

 -private_ip_address => '192.168.0.12'                    # single address
 -private_ip_address => ['192.168.0.12','192.168.0.13]    # multiple addresses
 -private_ip_address => 3                                 # autoselect three addresses

The mixed form of address, such as ['192.168.0.12','auto'] is not allowed in this call.

On success, this method returns true.

=cut

sub assign_private_ip_addresses {
    my $self = shift;
    my %args = $self->args(-network_interface_id => @_);
    $args{-private_ip_address} ||= $args{-private_ip_addresses};
    $args{-network_interface_id} && $args{-private_ip_address}
      or croak "usage: assign_private_ip_addresses(-network_interface_id=>\$id,-private_ip_address=>\\\@addresses)";
    my @parms = $self->single_parm('NetworkInterfaceId',\%args);

    if (!ref($args{-private_ip_address}) && $args{-private_ip_address} =~ /^\d+$/) {
	push @parms,('SecondaryPrivateIpAddressCount' => $args{-private_ip_address});
    } else {
	push @parms,$self->list_parm('PrivateIpAddress',\%args);
    }
    push @parms,('AllowReassignment' => $args{-allow_reassignment} ? 'true' : 'false')
	if exists $args{-allow_reassignment};
    $self->call('AssignPrivateIpAddresses',@parms);
}

=head2 $result = $ec2->unassign_private_ip_addresses(%args)

Unassign one or more secondary private IP addresses from a network
interface.

Required arguments:

 -network_interface_id    The network interface to which the IP address(es)
                          will be assigned.

 -private_ip_address      One or more secondary IP addresses, as a scalar string
 -private_ip_addresses    or array reference. (The two arguments are equivalent).


The following are valid arguments to -private_ip_address:

 -private_ip_address => '192.168.0.12'                    # single address
 -private_ip_address => ['192.168.0.12','192.168.0.13]    # multiple addresses

On success, this method returns true.

=cut

sub unassign_private_ip_addresses {
    my $self = shift;
    my %args = $self->args(-network_interface_id => @_);
    $args{-private_ip_address} ||= $args{-private_ip_addresses};
    $args{-network_interface_id} && $args{-private_ip_address}
      or croak "usage: assign_private_ip_addresses(-network_interface_id=>\$id,-private_ip_address=>\\\@addresses)";
    my @parms = $self->single_parm('NetworkInterfaceId',\%args);
    push @parms,$self->list_parm('PrivateIpAddress',\%args);
    $self->call('UnassignPrivateIpAddresses',@parms);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
