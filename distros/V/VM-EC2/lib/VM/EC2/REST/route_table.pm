package VM::EC2::REST::route_table;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    AssociateRouteTable               => sub { shift->{associationId}    },
    CreateRoute                       => 'boolean',
    CreateRouteTable                  => 'fetch_one,routeTable,VM::EC2::VPC::RouteTable',
    DeleteRoute                       => 'boolean',
    DeleteRouteTable                  => 'boolean',
    DescribeRouteTables               => 'fetch_items,routeTableSet,VM::EC2::VPC::RouteTable',
    DisassociateRouteTable            => 'boolean',
    ReplaceRoute                      => 'boolean',
    ReplaceRouteTableAssociation      => sub { shift->{newAssociationId} },
    );

=head1 NAME VM::EC2::REST::route_table

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods allow you to create and manipulate VPC route tables.

Implemented:
 AssociateRouteTable
 CreateRoute
 CreateRouteTable
 DeleteRoute
 DeleteRouteTable
 DescribeRouteTables
 DisassociateRouteTable
 ReplaceRoute
 ReplaceRouteTableAssociation

Unimplemented:
 (none)

=head2 $table = $ec2->create_route_table($vpc_id)

=head2 $table = $ec2->create_route_table(-vpc_id=>$id)

This method creates a new route table within the given VPC and returns
a VM::EC2::VPC::RouteTable object. By default, every route table
includes a local route that enables traffic to flow within the
VPC. You may add additional routes using create_route().

This method can be called using a single argument corresponding to VPC
ID for the new route table, or with the named argument form.

Required arguments:

 -vpc_id     A VPC ID or previously-created VM::EC2::VPC object.

=cut

sub create_route_table {
    my $self = shift;
    my %args = $self->args(-vpc_id => @_);
    $args{-vpc_id} 
      or croak "Usage: create_route_table(-vpc_id=>\$id)";
    my @parm = $self->single_parm(VpcId => \%args);
    return $self->call('CreateRouteTable',@parm);
}

=head2 $success = $ec2->delete_route_table($route_table_id)

=head2 $success = $ec2->delete_route_table(-route_table_id=>$id)

This method deletes the indicated route table and all the route
entries within it. It may not be called on the main route table, or if
the route table is currently associated with a subnet.

The method can be called with a single argument corresponding to the
route table's ID, or using the named form with argument -route_table_id.

=cut

sub delete_route_table {
    my $self = shift;
    my %args  = $self->args(-route_table_id=>@_);
    my @parm = $self->single_parm(RouteTableId=>\%args);
    return $self->call('DeleteRouteTable',@parm);
}

=head2 @tables = $ec2->describe_route_tables(@route_table_ids)

=head2 @tables = $ec2->describe_route_tables(\%filters)

=head2 @tables = $ec2->describe_route_tables(-route_table_id=> \@ids,
                                             -filter        => \%filters);

This method describes all or some of the route tables available to
you. You may use the filter to restrict the search to a particular
type of route table using one of the filters described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRouteTables.html.

Some of the commonly used filters are:

 vpc-id                  ID of the VPC the route table is in.
 association.subnet-id   ID of the subnet the route table is
                          associated with.
 route.state             State of the route, either 'active' or 'blackhole'
 tag:<key>               Value of a tag

=cut

sub describe_route_tables {
    my $self = shift;
    my %args  = $self->args(-route_table_id => @_);
    my @parm   = $self->list_parm('RouteTableId',\%args);
    push @parm,  $self->filter_parm(\%args);
    return $self->call('DescribeRouteTables',@parm);
}

=head2 $associationId = $ec2->associate_route_table($subnet_id => $route_table_id)

=head2 $associationId = $ec2->associate_route_table(-subnet_id      => $id,
                                                    -route_table_id => $id)

This method associates a route table with a subnet. Both objects must
be in the same VPC. You may use either string IDs, or
VM::EC2::VPC::RouteTable and VM::EC2::VPC::Subnet objects.

On success, an associationID is returned, which you may use to
disassociate the route table from the subnet later. The association ID
can also be found by searching through the VM::EC2::VPC::RouteTable
object.

Required arguments:

 -subnet_id      The subnet ID or a VM::EC2::VPC::Subnet object.

 -route_table_id The route table ID or a VM::EC2::VPC::RouteTable object.

It may be more convenient to call the
VM::EC2::VPC::Subnet->associate_route_table() or
VM::EC2::VPC::RouteTable->associate_subnet() methods, which are front
ends to this method.

=cut

sub associate_route_table {
    my $self = shift;
    my %args;
    if ($_[0] !~ /^-/ && @_ == 2) {
	@args{qw(-subnet_id -route_table_id)} = @_;
    } else {
	%args = @_;
    }
    $args{-subnet_id} && $args{-route_table_id}
       or croak "-subnet_id, and -route_table_id arguments required";
    my @param = ($self->single_parm(SubnetId=>\%args),
                $self->single_parm(RouteTableId=>\%args));
    return $self->call('AssociateRouteTable',@param);
}

=head2 $success = $ec2->dissociate_route_table($association_id)

=head2 $success = $ec2->dissociate_route_table(-association_id => $id)

This method disassociates a route table from a subnet. You must
provide the association ID (either returned from
associate_route_table() or found among the associations() of a
RouteTable object). You may use the short single-argument form, or the
longer named argument form with the required argument -association_id.

The method returns true on success.

=cut

sub disassociate_route_table {
    my $self = shift;
    my %args   = $self->args('-association_id',@_);
    my @params = $self->single_parm('AssociationId',\%args);
    return $self->call('DisassociateRouteTable',@params);
}

=head2 $new_association = $ec2->replace_route_table_association($association_id=>$route_table_id)


=head2 $new_association = $ec2->replace_route_table_association(-association_id => $id,
                                                                -route_table_id => $id)

This method changes the route table associated with a given
subnet. You must pass the replacement route table ID and the
association ID. To replace the main route table, use its association
ID and the ID of the route table you wish to replace it with.

On success, a new associationID is returned.

Required arguments:

 -association_id  The association ID

 -route_table_id   The route table ID or a M::EC2::VPC::RouteTable object.

=cut

sub replace_route_table_association {
    my $self = shift;
    my %args;
    if ($_[0] !~ /^-/ && @_ == 2) {
	@args{qw(-association_id -route_table_id)} = @_;
    } else {
	%args = @_;
    }
    $args{-association_id} && $args{-route_table_id}
       or croak "-association_id, and -route_table_id arguments required";
    my @param = $self->single_parm(AssociationId => \%args),
                $self->single_parm(RouteTableId  => \%args);
    return $self->call('ReplaceRouteTableAssociation',@param);
}

=head2 $success = $ec2->create_route($route_table_id,$destination,$target)

=head2 $success = $ec2->create_route(-route_table_id => $id,
                                     -destination_cidr_block => $block,
                                     -target=>$target)

This method creates a routing rule in a route table within a VPC. It
takes three mandatory arguments consisting of the route table, the
CIDR address block to match packet destinations against, and a target
to route matching packets to. The target may be an internet gateway, a
NAT instance, or a network interface ID.

Network packets are routed by matching their destination addresses
against a CIDR block. For example, 0.0.0.0/0 matches all addresses,
while 10.0.1.0/24 matches 10.0.1.* addresses. When a packet matches
more than one rule, the most specific matching routing rule is chosen.

In the named argument form, the following arguments are recognized:

 -route_table_id    The ID of a route table, or a VM::EC2::VPC::RouteTable
                    object.

 -destination_cidr_block
                    The CIDR address block to match against packet destinations.

 -destination       A shorthand version of -destination_cidr_block.

 -target            The destination of matching packets. See below for valid
                    targets.

The -target value can be any one of the following:

 1. A VM::EC2::VPC::InternetGateway object, or an internet gateway ID matching
    the regex /^igw-[0-9a-f]{8}$/

 2. A VM::EC2::Instance object, or an instance ID matching the regex
 /^i-[0-9a-f]{8}$/.

 3. A VM::EC2::NetworkInterface object, or a network interface ID
    matching the regex /^eni-[0-9a-f]{8}$/.

 4. A VM::EC2::VPC::PeeringConnection object, or a VPC peering connection ID
    matching the regex /^pcx-[0-9a-f]{8}$/.

On success, this method returns true.

=cut

sub create_route {
    my $self = shift;
    return $self->_manipulate_route('CreateRoute',@_);
}

=head2 $success = $ec2->delete_route($route_table_id,$destination_block)

This method deletes a route in the specified routing table. The
destination CIDR block is used to indicate which route to delete. On
success, the method returns true.

=cut

sub delete_route {
    my $self = shift;
    @_ == 2 or croak "Usage: delete_route(\$route_table_id,\$destination_block)";
    my %args;
    @args{qw(-route_table_id -destination_cidr_block)} = @_;
    my @parm = map {$self->single_parm($_,\%args)} qw(RouteTableId DestinationCidrBlock);
    return $self->call('DeleteRoute',@parm);
}

=head2 $success = $ec2->replace_route($route_table_id,$destination,$target)

=head2 $success = $ec2->replace_route(-route_table_id => $id,
                                     -destination_cidr_block => $block,
                                     -target=>$target)

This method replaces an existing routing rule in a route table within
a VPC. It takes three mandatory arguments consisting of the route
table, the CIDR address block to match packet destinations against,
and a target to route matching packets to. The target may be an
internet gateway, a NAT instance, or a network interface ID.

Network packets are routed by matching their destination addresses
against a CIDR block. For example, 0.0.0.0/0 matches all addresses,
while 10.0.1.0/24 matches 10.0.1.* addresses. When a packet matches
more than one rule, the most specific matching routing rule is chosen.

In the named argument form, the following arguments are recognized:

 -route_table_id    The ID of a route table, or a VM::EC2::VPC::RouteTable
                    object.

 -destination_cidr_block
                    The CIDR address block to match against packet destinations.

 -destination       A shorthand version of -destination_cidr_block.

 -target            The destination of matching packets. See below for valid
                    targets.

The -target value can be any one of the following:

 1. A VM::EC2::VPC::InternetGateway object, or an internet gateway ID matching
    the regex /^igw-[0-9a-f]{8}$/

 2. A VM::EC2::Instance object, or an instance ID matching the regex
 /^i-[0-9a-f]{8}$/.

 3. A VM::EC2::NetworkInterface object, or a network interface ID
    matching the regex /^eni-[0-9a-f]{8}$/.

 4. A VM::EC2::VPC::PeeringConnection object, or a VPC peering connection ID
    matching the regex /^pcx-[0-9a-f]{8}$/.

On success, this method returns true.

=cut

sub replace_route {
    my $self = shift;
    return $self->_manipulate_route('ReplaceRoute',@_);
}

sub _manipulate_route {
    my $self = shift;
    my $api_call = shift;

    my %args;
    if ($_[0] !~ /^-/ && @_ == 3) {
	@args{qw(-route_table_id -destination -target)} = @_;
    } else {
	%args = @_;
    }

    $args{-destination_cidr_block} ||= $args{-destination};
    $args{-destination_cidr_block} && $args{-route_table_id} && $args{-target}
       or croak "-route_table_id, -destination_cidr_block, and -target arguments required";

    # figure out what the target is.
    $args{-gateway_id}  = $args{-target} if eval{$args{-target}->isa('VM::EC2::VPC::InternetGateway')}
                                             || $args{-target} =~ /^igw-[0-9a-f]{8}$/;
    $args{-instance_id} = $args{-target} if eval{$args{-target}->isa('VM::EC2::Instance')}
                                             || $args{-target} =~ /^i-[0-9a-f]{8}$/;
    $args{-network_interface_id} = $args{-target} if eval{$args{-target}->isa('VM::EC2::NetworkInterface')}
                                             || $args{-target} =~ /^eni-[0-9a-f]{8}$/;
    $args{-vpc_peering_connection_id} = $args{-target} if eval{$args{-target}->isa('VM::EC2::VPC::PeeringConnection')}
                                             || $args{-target} =~ /^pcx-[0-9a-f]{8}$/;


    my @parm = map {$self->single_parm($_,\%args)} 
               qw(RouteTableId DestinationCidrBlock GatewayId InstanceId
                  NetworkInterfaceId VpcPeeringConnectionId);

    return $self->call($api_call,@parm);
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
