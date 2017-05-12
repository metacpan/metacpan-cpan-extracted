package VM::EC2::VPC;

=head1 NAME

VM::EC2::VPC

=head1 SYNOPSIS

 use VM::EC2;
 $ec2       - VM::EC2->new(...);
 $vpc       = $ec2->create_vpc('10.0.0.0/16')     or die $ec2->error_str;
 $subnet1   = $vpc->create_subnet('10.0.0.0/24')  or die $vpc->error_str;
 $gateway   = $vpc->create_internet_gateway       or die $vpc->error_str;
 $routeTbl  = $subnet1->create_route_table        or die $vpc->error_str;
 $routeTbl->create_route('0.0.0.0/0' => $gateway) or die $vpc->error_str;


=head1 DESCRIPTION

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 vpcId         -- ID of the VPC
 state         -- Current state of the VPC (pending, available)
 cidrBlock     -- The CIDR block the VPC covers.
 dhcpOptionsId -- The ID of the set of DHCP options you've associated
                  with the VPC, or "default".
 instanceTenancy  -- Either "dedicated" or "default"
 isDefault        -- Indicates if the VPC is a default VPC

In addition, this object supports the following convenience methods:

    dhcp_options()   -- Return a VM::EC2::VPC::DhcpOptions object.

    current_state()  -- Refresh the object and then return its state

    current_status() -- Same as above (for module consistency)

    set_dhcp_options($options) -- Associate the Dhcp option set with
          this VPC (DhcpOptionsId string or VM::EC2::VPC::DhcpOptions object).
          Use "default" or pass no arguments to assign no Dhcp options.

    internet_gateways() -- Return the list of internet gateways attached to
                           this VPC as a list of VM::EC2::VPC::InternetGateway.

    create_subnet($cidr_block [,$availability_zone] )
                        -- Create a subnet with the indicated CIDR block and
                           return the VM::EC2::VPC::Subnet object. The
                           optional $availability_zone argument selects the
                           zone for the subnet. Otherwise Amazon selects one
                           for you.

    create_internet_gateway()
                        -- Create an internet gateway and immediately attach
                           it to this VPC. If successful returns a 
                           VM::EC2::VPC::InternetGateway object.

    subnets()           -- Return the list of subnets attached to this VPC
                           as a list of VM::EC2::VPC::Subnet.

    route_tables()      -- Return the list of route tables attached to this VPC
                           as a list of VM::EC2::VPC::RouteTable.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
VPC ID.

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
use base 'VM::EC2::Generic';
use Carp 'croak';

sub valid_fields {
    my $self  = shift;
    return qw(vpcId state cidrBlock dhcpOptionsId instanceTenancy isDefault);
}

sub refresh {
    my $self = shift;
    my $i   = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_vpcs(-vpc_id=>$self->vpcId) unless $i;
    %$self = %$i if $i;
    return defined $i;
}

sub current_state {
    my $self = shift;
    $self->refresh;
    $self->state;
}

sub current_status {shift->current_state(@_)}

sub primary_id { shift->vpcId }

sub dhcp_options {
    my $self = shift;
    return $self->aws->describe_dhcp_options($self->dhcpOptionsId);
}

sub set_dhcp_options {
    my $self = shift;
    my $options = shift || 'default';
    return $self->aws->associate_dhcp_options($self => $options);
}

sub internet_gateways {
    my $self = shift;
    return $self->aws->describe_internet_gateways({'attachment.vpc-id'=>$self->vpcId});
}

sub subnets {
    my $self = shift;
    return $self->aws->describe_subnets({'vpc-id'=>$self->vpcId});
}

sub route_tables {
    my $self = shift;
    return $self->aws->describe_route_tables({'vpc-id'=>$self->vpcId});
}

sub attach_internet_gateway {
    my $self = shift;
    my $gw   = shift;
    return $self->aws->attach_internet_gateway($gw => $self->vpcId);
}

sub detach_internet_gateway {
    my $self = shift;
    my $gw   = shift || ($self->internet_gateways)[0];
    return $self->aws->detach_internet_gateway($gw=>$self->vpcId);
}

sub create_subnet {
    my $self = shift;
    my $cidr_block         = shift or croak "usage: create_subnet(\$cidr_block)";
    my $availability_zone  = shift;

    my %params = (-vpc_id=>$self->vpcId, -cidr_block=>$cidr_block);
    $params{-availability_zone} = $availability_zone if $availability_zone;

    my $result = $self->aws->create_subnet(%params);
    $self->refresh if $result;
    return $result;
}

sub delete_internet_gateway {
    my $self = shift;
    my $gateway = shift || ($self->internet_gateways)[0];
    $gateway or return;
    $self->detach_internet_gateway($gateway) or return;
    return $self->aws->delete_internet_gateway($gateway);
}

sub create_internet_gateway {
    my $self    = shift;
    my $gateway = $self->aws->create_internet_gateway() or return;
    my $attach  = $self->attach_internet_gateway($gateway);
    unless ($attach) {
	local $self->aws->{error};  # so that we get the error from the attach call
	$self->aws->delete_internet_gateway($gateway);
	return;
    }
    return $gateway;
}

sub isDefault {
    my $self = shift;
    my $default = $self->SUPER::isDefault;
    return $default eq 'true';
}

1;

