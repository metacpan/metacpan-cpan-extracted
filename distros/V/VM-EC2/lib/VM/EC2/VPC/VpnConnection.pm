package VM::EC2::VPC::VpnConnection;

=head1 NAME

VM::EC2::VPC::VpnConnection - VPC VPN connection

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2 = VM::EC2->new(...);
 my $vpn = $ec2->describe_vpn_connections(-vpn_connection_id=>'vpn-12345678');
 my $state = $vpn->state;
 my $vpn_gateway = $vpn->vpn_gateway;
 my $customer_gateway = $vpn->customer_gateway;

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC VPN connection, and is returned by
VM::EC2->describe_vpn_connections()

=head1 METHODS

These object methods are supported:

 vpnConnectionId              -- The ID of the VPN connection.
 state                        -- The current state of the VPN connection.
                                 Valid values: pending | available | deleting | deleted
 customerGatewayConfiguration -- Configuration information for the VPN connection's 
                                 customer gateway (in the native XML format). This 
                                 element is always present in the CreateVpnConnection
                                 response; however, it's present in the 
                                 DescribeVpnConnections response only if the VPN 
                                 connection is in the pending or available state.
 type                         -- The type of VPN connection (ipsec.1)
 customerGatewayId            -- ID of the customer gateway at your end of the VPN
                                 connection.
 vpnGatewayId                 -- ID of the virtual private gateway at the VPC end of 
                                 the VPN connection.
 tagSet                       -- Tags assigned to the resource.
 vgwTelemetry                 -- Information about the virtual private gateway.
 vpn_telemetry                -- Alias for vgwTelemetry

The following convenience methods are supported:

 vpn_gateway                  -- Returns a L<VM::EC2::VPC::VpnGateway> object

 customer_gateway             -- Returns a L<VM::EC2::VPC::CustomerGateway> object

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
vpnConnectionId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::CustomerGateway>
L<VM::EC2::VPC::VpnGateway>

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
use VM::EC2::VPC::VpnTunnelTelemetry;
use Carp 'croak';

sub primary_id { shift->vpnConnectionId }

sub valid_fields {
    my $self  = shift;
    return qw(vpnConnectionId state customerGatewayConfiguration type 
              customerGatewayId vpnGatewayId tagSet vgwTelemetry);
}

sub vgwTelemetry {
    my $self = shift;
    my $telemetry = $self->SUPER::vgwTelemetry;
    return VM::EC2::VPC::VpnTunnelTelemetry->new($telemetry,$self->aws);
}

sub vpn_telemetry { shift->vgwTelemetry }

sub vpn_gateway {
    my $self = shift;
    my $vpn_gw = $self->vpnGatewayId;
    return $self->aws->describe_vpn_gateways($vpn_gw);
}

sub customer_gateway {
    my $self = shift;
    my $cust_gw = $self->customerGatewayId;
    return $self->aws->describe_customer_gateways($cust_gw);
}

1;
