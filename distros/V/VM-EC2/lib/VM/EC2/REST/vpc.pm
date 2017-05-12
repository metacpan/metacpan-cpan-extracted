package VM::EC2::REST::vpc;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    AcceptVpcPeeringConnection        => 'fetch_one,vpcPeeringConnection,VM::EC2::VPC::PeeringConnection',
    CreateVpc                         => 'fetch_one,vpc,VM::EC2::VPC',
    CreateVpcPeeringConnection        => 'fetch_one,vpcPeeringConnection,VM::EC2::VPC::PeeringConnection',
    DeleteVpc                         => 'boolean',
    DeleteVpcPeeringConnection        => 'boolean',
    DescribeVpcs                      => 'fetch_items,vpcSet,VM::EC2::VPC',
    DescribeVpcAttribute              => 'boolean',
    DescribeVpcPeeringConnections     => 'fetch_items,vpcPeeringConnectionSet,VM::EC2::VPC::PeeringConnection',
    ModifyVpcAttribute                => 'boolean',
    RejectVpcPeeringConnection        => 'boolean',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::vpc

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

EC2 virtual private clouds (VPCs) provide facilities for creating
tiered applications combining public and private subnetworks, and for
extending your home/corporate network into the cloud.

Implemented:
 AcceptVpcPeeringConnection
 CreateVpc
 CreateVpcPeeringConnection
 DeleteVpc
 DeleteVpcPeeringConnection
 DescribeVpcPeeringConnections
 DescribeVpcs
 DescribeVpcAttribute
 ModifyVpcAttribute
 RejectVpcPeeringConnection

Unimplemented:
 (none)

=cut

=head2 $vpx = $ec2->accept_vpc_peering_connection(-vpc_peering_connection_id => $id)

=head2 $vpx = $ec2->accept_vpc_peering_connection($id)

Accepts a VPC peering connection request. To accept a request, the VPC peering
connection must be in the pending-acceptance state, and the request must come from
the owner of the peer VPC. 
Use describe_vpc_peering_connections(-filter => { 'status-code' => 'pending-acceptance' })
to view outstanding VPC peering connection requests.

Required arguments:

 -vpc_peering_connection_id    -- The ID of the VPC peering connection

Returns a L<VM::EC2::VPC::PeeringConnection> object.

=cut

sub accept_vpc_peering_connection {
    my $self = shift;
    my %args = $VEP->args(-vpc_peering_connection_id,@_);
    $args{-vpc_peering_connection_id} or
        croak "accept_vpc_peering_connection(): -vpc_peering_connection_id argument required";
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => 'VpcPeeringConnectionId',
        });
    return $self->call('AcceptVpcPeeringConnection',@param);
}

=head2 $vpc = $ec2->create_vpc(-cidr_block=>$cidr,-instance_tenancy=>$tenancy)

Create a new VPC. This can be called with a single argument, in which
case it is interpreted as the desired CIDR block, or 

 $vpc = $ec2->$ec2->create_vpc('10.0.0.0/16') or die $ec2->error_str;

Or it can be called with named arguments.

Required arguments:

 -cidr_block         The Classless Internet Domain Routing address, in the
                     form xx.xx.xx.xx/xx. One or more subnets will be allocated
                     from within this block.

Optional arguments:

 -instance_tenancy   "default" or "dedicated". The latter requests AWS to
                     launch all your instances in the VPC on single-tenant
                     hardware (at additional cost).

See
http://docs.amazonwebservices.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html
for a description of the valid CIDRs that can be used with EC2.

On success, this method will return a new VM::EC2::VPC object. You can
then use this object to create new subnets within the VPC:

 $vpc     = $ec2->create_vpc('10.0.0.0/16')    or die $ec2->error_str;
 $subnet1 = $vpc->create_subnet('10.0.0.0/24') or die $vpc->error_str;
 $subnet2 = $vpc->create_subnet('10.0.1.0/24') or die $vpc->error_str;
 $subnet3 = $vpc->create_subnet('10.0.2.0/24') or die $vpc->error_str;

=cut

sub create_vpc {
    my $self = shift;
    my %args = $VEP->args(-cidr_block,@_);
    $args{-cidr_block} or
        croak "create_vpc(): must provide a -cidr_block parameter";
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => 'CidrBlock',
            single_parm => 'instanceTenancy',
        });
    return $self->call('CreateVpc',@param);
}

=head2 $pcx = $ec2->create_vpc_peering_connection(-vpc_id        => $vpc_id,
                                                  -peer_vpc_id   => $peer_id,
                                                  -peer_owner_id => $owner_id)

Requests a VPC peering connection between two VPCs: a requester VPC and a peer
VPC with which to create the connection. The peer VPC can belong to another AWS
account. The requester VPC and peer VPC must not have overlapping CIDR blocks.

The owner of the peer VPC must accept the peering request to activate the
peering connection. The VPC peering connection request expires after seven days,
after which it cannot be accepted or rejected.

Required arguments:

 -vpc_id           The ID of the requester VPC

 -peer_vpc_id      The ID of the VPC with which the peering connection is to be
                   made

Conditional arguments:

 -peer_owner_id    The AWS account ID of the owner of the peer VPC
                   Required if the peer VPC is not in the same account as the
                   requester VPC

Returns a L<VM::EC2::VPC::PeeringConnection> object.

=cut

sub create_vpc_peering_connection {
    my $self = shift;
    my %args = @_;
    $args{-vpc_id} or
        croak "create_vpc_peering_connection(): -vpc_id argument required";
    $args{-peer_vpc_id} or
        croak "create_vpc_peering_connection(): -peer_vpc_id argument required";
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => [qw(VpcId PeerVpcId PeerOwnerId)],
        });
    return $self->call('CreateVpcPeeringConnection',@param);
}

=head2 @vpc = $ec2->describe_vpcs(@vpc_ids)

=head2 @vpc = $ec2->describe_vpcs(\%filter)

=head2 @vpc = $ec2->describe_vpcs(-vpc_id=>\@list,-filter=>\%filter)

Describe VPCs that you own and return a list of VM::EC2::VPC
objects. Call with no arguments to return all VPCs, or provide a list
of VPC IDs to return information on those only. You may also provide a
filter list, or named argument forms.

Optional arguments:

 -vpc_id      A scalar or array ref containing the VPC IDs you want
              information on.

 -filter      A hashref of filters to apply to the query.

The filters you can use are described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpcs.html

=cut

sub describe_vpcs {
    my $self = shift;
    my %args = $VEP->args(-vpc_id,@_);
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => 'VpcId',
            filter_parm => 'Filter',
        });
    return $self->call('DescribeVpcs',@param);
}

=head2 @vpx = $ec2->describe_vpc_peering_connections(@vpx_ids)

=head2 @vpx = $ec2->describe_vpc_peering_connections(\%filter)

=head2 @vpx = $ec2->describe_vpc_peering_connections(vpc_peering_connection_id=>\@list,-filter=>\%filter)

Describes one or more of your VPC peering connections.

Optional arguments:

 -vpc_peering_connection_id    A scalar or array ref containing the VPC IDs you want
                               information on.

 -filter                       A hashref of filters to apply to the query.

The filters you can use are described at
http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpcPeeringConnections.html

Returns a scalar or array of L<VM::EC2::VPC::PeeringConnection> objects.

=cut

sub describe_vpc_peering_connections {
    my $self = shift;
    my %args = $VEP->args(-vpc_peering_connection_id,@_);
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => 'VpcPeeringConnectionId',
            filter_parm => 'Filter',
        });
    return $self->call('DescribeVpcPeeringConnections',@param);
}

=head2 $success = $ec2->delete_vpc($vpc_id)

=head2 $success = $ec2->delete_vpc(-vpc_id=>$vpc_id)

Delete the indicated VPC, returning true if successful.

=cut

sub delete_vpc {
    my $self = shift;
    my %args = $VEP->args(-vpc_id,@_);
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => 'VpcId',
        });
    return $self->call('DeleteVpc',@param);
}

=head2 $success = $ec2->delete_vpc_peering_connection(-vpc_peering_connection_id => $id)

=head2 $success = $ec2->delete_vpc_peering_connection($id)

Deletes a VPC peering connection. Either the owner of the requester VPC or the
owner of the peer VPC can delete the VPC peering connection if it's in the
'active' state. The owner of the requester VPC can delete a VPC peering
connection in the 'pending-acceptance' state.

Required arguments:

 -vpc_peering_connection_id    The ID of the VPC peering connection to delete

Returns true if the deletion was successful.

=cut

sub delete_vpc_peering_connection {
    my $self = shift;
    my %args = $VEP->args(-vpc_peering_connection_id,@_);
    $args{-vpc_peering_connection_id} or
        croak "delete_vpc_peering_connection(): -vpc_peering_connection_id argument required";
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => 'VpcPeeringConnectionId',
        });
    return $self->call('DeleteVpcPeeringConnection',@param);
}

=head2 $attr = $ec2->describe_vpc_attribute(-vpc_id => $id, -attribute => $attr)

Describes an attribute of the specified VPC.

Required arguments:

 -vpc_id                  The ID of the VPC.

 -attribute               The VPC attribute.
                          Valid values:
                          enableDnsSupport | enableDnsHostnames

Returns true if attribute is set.

=cut

sub describe_vpc_attribute {
    my $self = shift;
    my %args  = @_;
    $args{-vpc_id} or croak "modify_vpc_attribute(): -vpc_id argument missing";
    $args{-attribute} or
        croak "modify_vpc_attribute(): -attribute argument missing";
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => [qw(VpcId Attribute)],
        });
    my $result = $self->call('DescribeVpcAttribute',@param);
    return $result && $result->attribute($args{-attribute}) eq 'true';
}

=head2 $success = $ec2->modify_vpc_attribute(-vpc_id               => $id,
                                             -enable_dns_support   => $boolen,
                                             -enable_dns_hostnames => $boolean)

Modify attributes of a VPC.

Required Arguments:

 -vpc_id                  The ID of the VPC.

One or more of the following arguments is required:

 -enable_dns_support      Specifies whether the DNS server provided
                          by Amazon is enabled for the VPC.

 -enable_dns_hostnames    Specifies whether DNS hostnames are provided
                          for the instances launched in this VPC. You
                          can only set this attribute to true if
                          -enable_dns_support is also true.

Returns true on success.

=cut

sub modify_vpc_attribute {
    my $self = shift;
    my %args  = @_;
    $args{-vpc_id} or croak "modify_vpc_attribute(): -vpc_id argument missing";
    $args{-enable_dns_support} || $args{-enable_dns_hostnames} or
        croak "modify_vpc_attribute(): -enable_dns_support or -enable_dns_hostnames argument required";
    my @param = $VEP->format_parms(\%args,
        {
            boolean_parm => [qw(enableDnsSupport enableDnsHostnames)],
            single_parm  => 'VpcId',
        });
    return $self->call('ModifyVpcAttribute',@param);
}

=head2 $success = $ec2->reject_vpc_peering_connection(-vpc_peering_connection_id => $id)

Rejects a VPC peering connection request. The VPC peering connection must be in
the 'pending-acceptance' state.
Use describe_vpc_peering_connections(-filter => { 'status-code' => 'pending-acceptance' })
to view outstanding VPC peering connection requests.

Required arguments:

 -vpc_peering_connection_id    The ID of the VPC peering connection to delete

Returns true if the deletion was successful.

=cut

sub reject_vpc_peering_connection {
    my $self = shift;
    my %args = $VEP->args(-vpc_peering_connection_id,@_);
    $args{-vpc_peering_connection_id} or
        croak "reject_vpc_peering_connection(): -vpc_peering_connection_id argument required";
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => 'VpcPeeringConnectionId',
        });
    return $self->call('RejectVpcPeeringConnection',@param);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
