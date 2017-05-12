package VM::EC2::REST::vpn_gateway;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    AttachVpnGateway                  => sub { shift->{attachment}{state} },
    CreateVpnGateway                  => 'fetch_one,vpnGateway,VM::EC2::VPC::VpnGateway',
    DeleteVpnGateway                  => 'boolean',
    DescribeVpnGateways               => 'fetch_items,vpnGatewaySet,VM::EC2::VPC::VpnGateway',
    DetachVpnGateway                  => 'boolean',
    DisableVgwRoutePropagation        => 'boolean',
    EnableVgwRoutePropagation         => 'boolean',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::vpn_gateway

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods create and manage Virtual Private Network Gateways (VGW).

Implemented:
 AttachVpnGateway
 CreateVpnGateway
 DeleteVpnGateway
 DescribeVpnGateways
 DisableVgwRoutePropagation
 EnableVgwRoutePropagation

Unimplemented:
 (none)

=head2 @gtwys = $ec2->describe_vpn_gateways(-vpn_gateway_id=>\@ids,
                                            -filter        =>\%filters)

=head2 @gtwys = $ec2->describe_vpn_gateways(@vpn_gateway_ids)

=head2 @gtwys = $ec2->describe_vpn_gateways(%filters)

Provides information on VPN gateways.

Return a series of VM::EC2::VPC::VpnGateway objects.  When called with no
arguments, returns all VPN gateways.  Pass a list of VPN gateway IDs or
use the assorted filters to restrict the search.

Optional parameters are:

 -vpn_gateway_id         ID of the gateway(s) to return information on. 
                         This can be a string scalar, or an arrayref.

 -filter                 Tags and other filters to apply.

The filter argument is a hashreference in which the keys are the
filter names, and the values are the match strings. Some filters
accept wildcards.

There are a number of filters, which are listed in full at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnGateways.html

Here is a alpha-sorted list of filter names: attachment.state,
attachment.vpc-id, availability-zone, state, tag-key, tag-value, tag:key, type,
vpn-gateway-id

=cut

sub describe_vpn_gateways {
    my $self = shift;
    my %args = $VEP->args(-vpn_gateway_id,@_);
    my @params = $VEP->format_parms(\%args,
                                    {
                                        list_parm   => 'VpnGatewayId',
                                        filter_parm => 'Filter',
                                    });
    return $self->call('DescribeVpnGateways',@params);
}

=head2 $vpn_gateway = $ec2->create_vpn_gateway(-type=>$type)

=head2 $vpn_gateway = $ec2->create_vpn_gateway($type)

=head2 $vpn_gateway = $ec2->create_vpn_gateway

Creates a new virtual private gateway. A virtual private gateway is the
VPC-side endpoint for a VPN connection. You can create a virtual private 
gateway before creating the VPC itself.

 -type switch is optional as there is only one type as of API 2012-06-15

Returns a VM::EC2::VPC::VpnGateway object on success

=cut

sub create_vpn_gateway {
    my $self = shift;
    my %args = $VEP->args(-type,@_);
    $args{-type} ||= 'ipsec.1';
    my @params = $VEP->format_parms(\%args,
                                    {
                                        list_parm => 'Type',
                                    });
    return $self->call('CreateVpnGateway',@params);
}

=head2 $success = $ec2->delete_vpn_gateway(-vpn_gateway_id=>$id);

=head2 $success = $ec2->delete_vpn_gateway($id);

Deletes a virtual private gateway.  Use this when a VPC and all its associated 
components are no longer needed.  It is recommended that before deleting a 
virtual private gateway, detach it from the VPC and delete the VPN connection.
Note that it is not necessary to delete the virtual private gateway if the VPN 
connection between the VPC and data center needs to be recreated.

Arguments:

 -vpn_gateway_id    -- The ID of the VPN gateway to delete.

Returns true on successful deletion

=cut

sub delete_vpn_gateway {
    my $self = shift;
    my %args = $VEP->args(-vpn_gateway_id,@_);
    $args{-vpn_gateway_id} or
        croak "delete_vpn_gateway(): -vpn_gateway_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'VpnGatewayId',
                                    });
    return $self->call('DeleteVpnGateway',@params);
}

=head2 $state = $ec2->attach_vpn_gateway(-vpn_gateway_id=>$vpn_gtwy_id,
                                         -vpc_id        =>$vpc_id)

Attaches a virtual private gateway to a VPC.

Arguments:

 -vpc_id          -- The ID of the VPC to attach the VPN gateway to

 -vpn_gateway_id  -- The ID of the VPN gateway to attach

Returns the state of the attachment, one of:
   attaching | attached | detaching | detached

=cut

sub attach_vpn_gateway {
    my $self = shift;
    my %args = @_;
    $args{-vpn_gateway_id} or
        croak "attach_vpn_gateway(): -vpn_gateway_id argument missing";
    $args{-vpc_id} or
        croak "attach_vpn_gateway(): -vpc_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(VpnGatewayId VpcId)],
                                    });
    return $self->call('AttachVpnGateway',@params);
}

=head2 $success = $ec2->detach_vpn_gateway(-vpn_gateway_id=>$vpn_gtwy_id,
                                           -vpc_id        =>$vpc_id)

Detaches a virtual private gateway from a VPC. You do this if you're
planning to turn off the VPC and not use it anymore. You can confirm
a virtual private gateway has been completely detached from a VPC by
describing the virtual private gateway (any attachments to the 
virtual private gateway are also described).

You must wait for the attachment's state to switch to detached 
before you can delete the VPC or attach a different VPC to the 
virtual private gateway.

Arguments:

 -vpc_id          -- The ID of the VPC to detach the VPN gateway from

 -vpn_gateway_id  -- The ID of the VPN gateway to detach

Returns true on successful detachment.

=cut

sub detach_vpn_gateway {
    my $self = shift;
    my %args = @_;
    $args{-vpn_gateway_id} or
        croak "detach_vpn_gateway(): -vpn_gateway_id argument missing";
    $args{-vpc_id} or
        croak "detach_vpn_gateway(): -vpc_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(VpnGatewayId VpcId)],
                                    });
    return $self->call('DetachVpnGateway',@params);
}

=head2 $success = $ec2->enable_vgw_route_propagation(-route_table_id=>$rt_id,
                                                     -gateway_id    =>$gtwy_id)

Enables a virtual private gateway (VGW) to propagate routes to the routing
tables of an Amazon VPC.

Arguments:

 -route_table_id        -- The ID of the routing table.

 -gateway_id            -- The ID of the virtual private gateway.

Returns true on successful enablement.

=cut

sub enable_vgw_route_propagation {
    my $self = shift;
    my %args = @_;
    $args{-route_table_id} or
        croak "enable_vgw_route_propagation(): -route_table_id argument missing";
    $args{-gateway_id} or
        croak "enable_vgw_route_propagation(): -gateway_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(RouteTableId GatewayId)],
                                    });
    return $self->call('EnableVgwRoutePropagation',@params);
}

=head2 $success = $ec2->disable_vgw_route_propagation(-route_table_id=>$rt_id,
                                                      -gateway_id    =>$gtwy_id)

Disables a virtual private gateway (VGW) from propagating routes to the routing
tables of an Amazon VPC.

Arguments:

 -route_table_id        -- The ID of the routing table.

 -gateway_id            -- The ID of the virtual private gateway.

Returns true on successful disablement.

=cut

sub disable_vgw_route_propagation {
    my $self = shift;
    my %args = @_;
    $args{-route_table_id} or
        croak "disable_vgw_route_propagation(): -route_table_id argument missing";
    $args{-gateway_id} or
        croak "disable_vgw_route_propagation(): -gateway_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(RouteTableId GatewayId)],
                                    });
    return $self->call('DisableVgwRoutePropagation',@params);
}

# aliases for backward compatibility to a typo
*enable_vgw_route_propogation = \&enable_vgw_route_propagation;
*disable_vgw_route_propogation = \&dispable_vgw_route_propagation;

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
