package VM::EC2::VPC::Route;

=head1 NAME

VM::EC2::VPC::Route -- An entry in a VPC routing table

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2     = VM::EC2->new(...);
 my $table  = $ec2->describe_route_tables('rtb-123456');
 my @routes = $table->routes;

 foreach my $r (@routes) {
       print $r->destinationCidrBlock,"\n",
             $r->gatewayId,"\n",
             $r->instanceId,"\n",
             $r->instanceOwnerId,"\n",
             $r->networkInterfaceId,"\n",
             $r->state,"\n"
       my $target = $r->target,"\n";  # an instance, gateway or network interface object
}

=head1 DESCRIPTION

This object supports the EC2 Virtual Private Cloud route interface,
and is used to control the routing of packets within and between
subnets. Each route has a destination CIDR address block, and a target
gateway, instance or network interface that will receive packets whose
destination matches the block. Routes are matched in order from the
most specific to the most general.

=head1 METHODS

These object methods are supported:
 
 destinationCidrBlock -- The CIDR address block used in the destination
                         match. For example 0.0.0/0 for all packets.
 gatewayId            -- The ID of an internet gateway attached to your
                         VPC.
 instanceId           -- The ID of an instance in your VPC to act as the
                         destination for packets. Typically this will be
                         a NAT instance.
 instanceOwnerId      -- The account number of the owner of the instance.
 networkInterfaceId   -- The ID of an Elastic Network Interface to receive
                         packets matching the destination
 state                -- One of "active" or "blackhole". The blackhole state
                         applies when the route's target isn't usable for
                         one reason or another.

In addition, the following convenience methods are provided:

 target       -- Return the target of the route. This method will return
                 a VM::EC2::Instance, VM::EC2::VPC::InternetGateway, or
                 VM::EC2::NetworkInterface object depending on the nature
                 of the target.

 instance     -- If an instance is the target, return the corresponding
                 VM::EC2::Instance object

 gateway      -- If a gateway is the target, return the corresponding
                 VM::EC2::VPC::InternetGateway object.

 network_interface -- If a network interface is the target, return the
                 corresponding VM::EC2::NetworkInterface object.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
destinationCidrBlock

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
use Carp 'croak';
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self  = shift;
    return qw(destinationCidrBlock gatewayId instanceId instanceOwnerId networkInterfaceId state);
}

sub short_name { shift->destinationCidrBlock }

sub instance {
    my $self = shift;
    my $instance = $self->instanceId or return;
    return $self->aws->describe_instances($instance);
}

sub gateway {
    my $self = shift;
    my $gw   = $self->gatewayId or return;
    return $self->aws->describe_internet_gateways($gw);
}

sub network_interface {
    my $self = shift;
    my $ni   = $self->networkInterfaceId or return;
    return $self->aws->describe_network_interfaces($ni);
}

sub target {
    my $self = shift;
    return $self->instance || $self->gateway || $self->network_interface;
}

1;

