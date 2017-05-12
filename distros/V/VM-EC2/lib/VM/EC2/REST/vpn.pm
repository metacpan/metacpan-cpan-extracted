package VM::EC2::REST::vpn;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateVpnConnection               => 'fetch_one,vpnConnection,VM::EC2::VPC::VpnConnection',
    CreateVpnConnectionRoute          => 'boolean',
    DeleteVpnConnection               => 'boolean',
    DeleteVpnConnectionRoute          => 'boolean',
    DescribeVpnConnections            => 'fetch_items,vpnConnectionSet,VM::EC2::VPC::VpnConnection',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::vpn

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods create and manage the connections of Virtual Private
Network (VPN) to Amazon Virtual Private Clouds (VPC).

Implemented:
 CreateVpnConnection
 CreateVpnConnectionRoute
 DeleteVpnConnection
 DeleteVpnConnectionRoute
 DescribeVpnConnections

Unimplemented:
 (none)

=head2 @vpn_connections = $ec2->describe_vpn_connections(-vpn_connection_id=>\@ids,
                                                         -filter=>\%filters);

=head2 @vpn_connections = $ec2->describe_vpn_connections(@vpn_connection_ids)

=head2 @vpn_connections = $ec2->describe_vpn_connections(%filters);

Gives information about VPN connections

Returns a series of VM::EC2::VPC::VpnConnection objects.

Optional parameters are:

 -vpn_connection_id      ID of the connection(s) to return information on. 
                         This can be a string scalar, or an arrayref.

 -filter                 Tags and other filters to apply.

The filter argument is a hashreference in which the keys are the
filter names, and the values are the match strings. Some filters
accept wildcards.

There are a number of filters, which are listed in full at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnConnections.html

Here is a alpha-sorted list of filter names:
customer-gateway-configuration, customer-gateway-id, state,
tag-key, tag-value, tag:key, type, vpn-connection-id,
vpn-gateway-id

=cut

sub describe_vpn_connections {
    my $self = shift;
    my %args = $VEP->args(-vpn_connection_id,@_);
    my @params = $VEP->format_parms(\%args,
                                    {
                                        list_parm   => 'VpnConnectionId',
                                        filter_parm => 'Filter',
                                    });
    return $self->call('DescribeVpnConnections',@params);
}

=head2 $vpn_connection = $ec2->create_vpn_connection(-type               =>$type,
                                                     -customer_gateway_id=>$gtwy_id,
                                                     -vpn_gateway_id     =>$vpn_id)

Creates a new VPN connection between an existing virtual private 
gateway and a VPN customer gateway. The only supported connection 
type is ipsec.1.

Required Arguments:

 -customer_gateway_id        -- The ID of the customer gateway

 -vpn_gateway_id             -- The ID of the VPN gateway

Optional arguments:
 -type                       -- Default is the only currently available option:
                                ipsec.1 (API 2012-06-15)

 -options_static_routes_only -- Indicates whether or not the VPN connection
                                requires static routes. If you are creating a VPN
                                connection for a device that does not support
                                BGP, you must specify this value as true.

 -static_routes_only         -- Alias for -options_static_routes_only

Returns a L<VM::EC2::VPC::VpnConnection> object.

=cut

sub create_vpn_connection {
    my $self = shift;
    my %args = @_;
    $args{-type} ||= 'ipsec.1';
    $args{-vpn_gateway_id} or
        croak "create_vpn_connection(): -vpn_gateway_id argument missing";
    $args{-customer_gateway_id} or
        croak "create_vpn_connection(): -customer_gateway_id argument missing";
    $args{'-options_static_routes_only'} ||= $args{-static_routes_only};
    my @params = $VEP->format_parms(\%args,
                                    {
                                        boolean_parm => 'Options.StaticRoutesOnly',
                                        single_parm  => [qw(VpnGatewayId CustomerGatewayId Type)],
                                    });
    return $self->call('CreateVpnConnection',@params);
}

=head2 $success = $ec2->delete_vpn_connection(-vpn_connection_id=>$vpn_id)

=head2 $success = $ec2->delete_vpn_connection($vpn_id)

Deletes a VPN connection. Use this if you want to delete a VPC and 
all its associated components. Another reason to use this operation
is if you believe the tunnel credentials for your VPN connection 
have been compromised. In that situation, you can delete the VPN 
connection and create a new one that has new keys, without needing
to delete the VPC or virtual private gateway. If you create a new 
VPN connection, you must reconfigure the customer gateway using the
new configuration information returned with the new VPN connection ID.

Arguments:

 -vpn_connection_id       -- The ID of the VPN connection to delete

Returns true on successful deletion.

=cut

sub delete_vpn_connection {
    my $self = shift;
    my %args = $VEP->args(-vpn_connection_id,@_);
    $args{-vpn_connection_id} or
        croak "delete_vpn_connection(): -vpn_connection_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm  => 'VpnConnectionId',
                                    });
    return $self->call('DeleteVpnConnection',@params);
}

=head2 $success = $ec2->create_vpn_connection_route(-destination_cidr_block=>$cidr,
                                                    -vpn_connection_id     =>$id)

Creates a new static route associated with a VPN connection between an existing
virtual private gateway and a VPN customer gateway. The static route allows
traffic to be routed from the virtual private gateway to the VPN customer
gateway.

Arguments:

 -destination_cidr_block     -- The CIDR block associated with the local subnet
                                 of the customer data center.

 -vpn_connection_id           -- The ID of the VPN connection.

Returns true on successsful creation.

=cut

sub create_vpn_connection_route {
    my $self = shift;
    my %args = @_;
    $args{-destination_cidr_block} or
        croak "create_vpn_connection_route(): -destination_cidr_block argument missing";
    $args{-vpn_connection_id} or
        croak "create_vpn_connection_route(): -vpn_connection_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm  => [qw(DestinationCidrBlock VpnConnectionId)],
                                    });
    return $self->call('CreateVpnConnectionRoute',@params);
}

=head2 $success = $ec2->delete_vpn_connection_route(-destination_cidr_block=>$cidr,
                                                    -vpn_connection_id     =>$id)

Deletes a static route associated with a VPN connection between an existing
virtual private gateway and a VPN customer gateway. The static route allows
traffic to be routed from the virtual private gateway to the VPN customer
gateway.

Arguments:

 -destination_cidr_block     -- The CIDR block associated with the local subnet
                                 of the customer data center.

 -vpn_connection_id           -- The ID of the VPN connection.

Returns true on successsful deletion.

=cut

sub delete_vpn_connection_route {
    my $self = shift;
    my %args = @_;
    $args{-destination_cidr_block} or
        croak "delete_vpn_connection_route(): -destination_cidr_block argument missing";
    $args{-vpn_connection_id} or
        croak "delete_vpn_connection_route(): -vpn_connection_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm  => [qw(DestinationCidrBlock VpnConnectionId)],
                                    });
    return $self->call('DeleteVpnConnectionRoute',@params);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.
Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.
Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
