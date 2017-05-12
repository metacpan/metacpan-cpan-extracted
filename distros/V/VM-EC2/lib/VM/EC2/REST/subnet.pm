package VM::EC2::REST::subnet;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateSubnet                      => 'fetch_one,subnet,VM::EC2::VPC::Subnet',
    DeleteSubnet                      => 'boolean',
    DescribeSubnets                   => 'fetch_items,subnetSet,VM::EC2::VPC::Subnet',
    ModifySubnetAttribute             => 'boolean',
);

=head1 NAME VM::EC2::REST::subnet

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods manage subnet objects and the routing among them. A VPC
may have a single subnet or many, and routing rules determine whether
the subnet has access to the internet ("public"), is entirely private,
or is connected to a customer gateway device to form a Virtual Private
Network (VPN) in which your home network's address space is extended
into the Amazon VPC. 

All instances in a VPC are located in one subnet or another. Subnets
may be public or private, and are organized in a star topology with a
logical router in the middle.

Although all these methods can be called from VM::EC2 objects, many
are more conveniently called from the VM::EC2::VPC object family. This
allows for steps that typically follow each other, such as creating a
route table and associating it with a subnet, happen
automatically. For example, this series of calls creates a VPC with a
single subnet, creates an Internet gateway attached to the VPC,
associates a new route table with the subnet and then creates a
default route from the subnet to the Internet gateway.

 $vpc       = $ec2->create_vpc('10.0.0.0/16')     or die $ec2->error_str;
 $subnet1   = $vpc->create_subnet('10.0.0.0/24')  or die $vpc->error_str;
 $gateway   = $vpc->create_internet_gateway       or die $vpc->error_str;
 $routeTbl  = $subnet->create_route_table         or die $vpc->error_str;
 $routeTbl->create_route('0.0.0.0/0' => $gateway) or die $vpc->error_str;

Implemented:
 CreateSubnet
 DeleteSubnet
 DescribeSubnets

Unimplemented:
 (none)

=head2 $subnet = $ec2->create_subnet(-vpc_id=>$id,-cidr_block=>$block)

This method creates a new subnet within the given VPC. Pass a VPC
object or VPC ID, and a CIDR block string. If successful, the method
will return a VM::EC2::VPC::Subnet object.

Required arguments:

 -vpc_id     A VPC ID or previously-created VM::EC2::VPC object.

 -cidr_block A CIDR block string in the form "xx.xx.xx.xx/xx". The
             CIDR address must be within the CIDR block previously
             assigned to the VPC, and must not overlap other subnets
             in the VPC.

Optional arguments:

 -availability_zone  The availability zone for the instances launched
                     within this instance, either an availability zone
                     name, or a VM::EC2::AvailabilityZone object. If
                     this is not specified, then AWS chooses a zone for
                     you automatically.

=cut

sub create_subnet {
    my $self = shift;
    my %args = @_;
    $args{-vpc_id} && $args{-cidr_block} 
      or croak "Usage: create_subnet(-vpc_id=>\$id,-cidr_block=>\$block)";
    my @parm = map {$self->single_parm($_ => \%args)} qw(VpcId CidrBlock AvailabilityZone);
    return $self->call('CreateSubnet',@parm);
}

=head2 $success = $ec2->delete_subnet($subnet_id)

=head2 $success = $ec2->delete_subnet(-subnet_id=>$id)

This method deletes the indicated subnet. It may be called with a
single argument consisting of the subnet ID, or a named argument form
with the argument -subnet_id.

=cut

sub delete_subnet {
    my $self = shift;
    my %args  = $self->args(-subnet_id=>@_);
    my @parm = $self->single_parm(SubnetId=>\%args);
    return $self->call('DeleteSubnet',@parm);
}

=head2 @subnets = $ec2->describe_subnets(@subnet_ids)

=head2 @subnets = $ec2->describe_subnets(\%filters)

=head2 @subnets = $ec2->describe_subnets(-subnet_id=>$id,
                                         -filter   => \%filters)

This method returns a list of VM::EC2::VPC::Subnet objects. Called
with no arguments, it returns all Subnets (not filtered by VPC
Id). Pass a list of subnet IDs or a filter hashref in order to
restrict the search.

Optional arguments:

 -subnet_id     Scalar or arrayref of subnet IDs.
 -filter        Hashref of filters.

Available filters are described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSubnets.html

=cut

sub describe_subnets {
    my $self = shift;
    my %args  = $self->args(-subnet_id => @_);
    my @parm   = $self->list_parm('SubnetId',\%args);
    push @parm,  $self->filter_parm(\%args);
    return $self->call('DescribeSubnets',@parm);
}

=head2 $success = $ec2->modify_subnet_attribute(-subnet_id => $sub_id, -map_public_ip_on_launch => $boolean)

Modifies a subnet attribute.

Required arguments:

 -subnet_id                 The ID of the subnet to modify.

 -map_public_ip_on_launch   Modifies the public IP addressing behavior for the
                            subnet. Specify true to indicate that instances
                            launched into the specified subnet should be
                            assigned a public IP address. If set to true, the
                            instance receives a public IP address only if the
                            instance is launched with a single, new network
                            interface with the device index of 0.

Returns true on success.

=cut

sub modify_subnet_attribute {
    my $self = shift;
    my %args = @_;
    $args{-subnet_id} && $args{-map_public_ip_on_launch} 
      or croak "Usage: modify_subnet_attribute(-subnet_id=>\$id,-map_public_ip_on_launch=>\$boolean)";
    my @parm = $self->single_parm(SubnetId=>\%args);
    push @parm, $self->boolean_value_parm(MapPublicIpOnLaunch=>\%args);
    return $self->call('ModifySubnetAttribute',@parm);
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
