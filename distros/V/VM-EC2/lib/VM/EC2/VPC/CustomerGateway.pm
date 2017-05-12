package VM::EC2::VPC::CustomerGateway;

=head1 NAME

VM::EC2::VPC::CustomerGateway - Object describing an Amazon EC2
Virtual Private Cloud customer gateway

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2      = VM::EC2->new(...);
 my $gtwy     = $ec2->describe_customer_gateways(-customer_gatway_id=>'cgw-12345678');
 print $gtwy->ipAddress,"\n",
       $gtwy->state,"\n";

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC route, and is returned by
VM::EC2->describe_customer_gateways() and ->create_customer_gateway()

=head1 METHODS

These object methods are supported:

 customerGatewayId        -- The ID of the customer gateway.
 state                    -- The current state of the customer gateway.
                             Valid values: pending | available | deleting | deleted
 type                     -- The type of VPN connection the customer gateway
                             supports (ipsec.1).
 ipAddress                -- The Internet-routable IP address of the customer
                             gateway's outside interface.
 bgpAsn                   -- The customer gateway's Border Gateway Protocol (BGP) 
                             Autonomous System Number (ASN).
 tagSet                   -- Tags assigned to the resource.

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
customerGatewayId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use Carp 'croak';

sub primary_id { shift->customerGatewayId}

sub valid_fields {
    my $self  = shift;
    return qw(customerGatewayId state type ipAddress bgpAsn tagSet);
}

1;
