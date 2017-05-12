package VM::EC2::VPC::VpnGateway;

=head1 NAME

VM::EC2::VPC::VpnGateway - Virtual Private Cloud VPN gateway

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2   = VM::EC2->new(...);
 my $gtwy  = $ec2->describe_vpn_gateways(-vpn_gatway_id=>'vgw-12345678');
 my $state = $gtwy->state;

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC route, and is returned by
VM::EC2->describe_internet_gateways() and ->create_internet_gateway()

=head1 METHODS

These object methods are supported:

 vpnGatewayId        -- The ID of the VPN gateway.
 state               -- The current state of the virtual private gateway.
                        Valid values: pending | available | deleting | deleted
 type                -- The type of VPN connection the virtual private gateway
                        supports (ipsec.1)
 availabilityZone    -- The Availability Zone where the virtual private gateway
                        was created as a L<VM::EC2::AvailabilityZone> object.
 attachments         -- A list of VPCs attached to the VPN gateway.
 tagSet              -- Tags assigned to the resource.
 zone                -- Alias for availabilityZone.

The following convenience methods are supported:

 attachments         --  Returns a series of L<VM::EC2::VPC::VpnGateway::Attachment>
                         objects

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
vpnGatewayId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::VpnGateway::Attachment>

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
use VM::EC2::VPC::VpnGateway::Attachment;
use Carp 'croak';

sub primary_id { shift->vpnGatewayId }

sub valid_fields {
    my $self  = shift;
    return qw(vpnGatewayId state type availabilityZone attachments tagSet);
}

sub attachments {
    my $self = shift;
    my $attach = $self->SUPER::attachments;
    return map { VM::EC2::VPC::VpnGateway::Attachment->new($_,$self->aws) } @{$attach->{item}};
}

sub availabilityZone {
    my $self = shift;
    my $zone = $self->SUPER::availabilityZone;
    return $self->aws->describe_availability_zones($zone) if $zone;
    return $self->aws->describe_availability_zones();
}

sub zone { shift->availabilityZone }

1;

