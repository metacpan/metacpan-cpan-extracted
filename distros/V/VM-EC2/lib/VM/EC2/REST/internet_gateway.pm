package VM::EC2::REST::internet_gateway;

use strict;
use VM::EC2 '';   # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateInternetGateway             => 'fetch_one,internetGateway,VM::EC2::VPC::InternetGateway',
    DescribeInternetGateways          => 'fetch_items,internetGatewaySet,VM::EC2::VPC::InternetGateway',
    DeleteInternetGateway             => 'boolean',
    AttachInternetGateway             => 'boolean',
    DetachInternetGateway             => 'boolean',
    );

=head1 NAME VM::EC2::REST::internet_gateway

=head1 SYNOPSIS

 use VM::EC2 ':vpc'

=head1 METHODS

These methods provide methods for creating, associating and deleting
Internet Gateway objects.

Implemented:
 AttachInternetGateway
 CreateInternetGateway
 DeleteInternetGateway
 DescribeInternetGateways
 DetachInternetGateway

Unimplemented:
 (none)

=head2 $gateway = $ec2->create_internet_gateway()

This method creates a new Internet gateway. It takes no arguments and
returns a VM::EC2::VPC::InternetGateway object. Gateways are initially
independent of any VPC, but later can be attached to one or more VPCs
using attach_internet_gateway().

=cut

sub create_internet_gateway {
    my $self = shift;
    return $self->call('CreateInternetGateway');
}

=head2 $success = $ec2->delete_internet_gateway($internet_gateway_id)

=head2 $success = $ec2->delete_internet_gateway(-internet_gateway_id=>$id)

This method deletes the indicated internet gateway. It may be called
with a single argument corresponding to the route table's ID, or using
the named form with argument -internet_gateway_id.

=cut

sub delete_internet_gateway {
    my $self = shift;
    my %args  = $self->args(-internet_gateway_id=>@_);
    my @parm = $self->single_parm(InternetGatewayId=>\%args);
    return $self->call('DeleteInternetGateway',@parm);
}


=head2 @gateways = $ec2->describe_internet_gateways(@gateway_ids)

=head2 @gateways = $ec2->describe_internet_gateways(\%filters)

=head2 @gateways = $ec2->describe_internet_gateways(-internet_gateway_id=>\@ids,
                                                    -filter             =>\$filters)

This method describes all or some of the internet gateways available
to you. You may use the filter to restrict the search to a particular
type of internet gateway using one or more of the filters described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInternetGateways.html.

Some of the commonly used filters are:

 attachment.vpc-id       ID of one of the VPCs the gateway is attached to
 attachment.state        State of the gateway, always "available"
 tag:<key>               Value of a tag

On success this method returns a list of VM::EC2::VPC::InternetGateway
objects.

=cut

sub describe_internet_gateways {
    my $self = shift;
    my %args  = $self->args(-internet_gateway_id => @_);
    my @parm   = $self->list_parm('InternetGatewayId',\%args);
    push @parm,  $self->filter_parm(\%args);
    return $self->call('DescribeInternetGateways',@parm);
}

=head2 $boolean = $ec2->attach_internet_gateway($internet_gateway_id,$vpc_id)

=head2 $boolean = $ec2->attach_internet_gateway(-internet_gateway_id => $id,
                                                -vpc_id              => $id)

This method attaches an internet gateway to a VPC.  You can use
internet gateway and VPC IDs, or their corresponding
VM::EC2::VPC::InternetGateway and VM::EC2::VPC objects.

Required arguments:

 -internet_gateway_id ID of the network interface to attach.
 -vpc_id              ID of the instance to attach the interface to.

On success, this method a true value.

Note that it may be more convenient to attach and detach gateways via
methods in the VM::EC2::VPC and VM::EC2::VPC::Gateway objects.

 $vpc->attach_internet_gateway($gateway);
 $gateway->attach($vpc);

=cut

sub attach_internet_gateway {
    my $self = shift;
    my %args; 
    if ($_[0] !~ /^-/ && @_ == 2) { 
	@args{qw(-internet_gateway_id -vpc_id)} = @_; 
    } else { 
	%args = @_;
    }
    $args{-internet_gateway_id} && $args{-vpc_id}
       or croak "-internet_gateway_id and-vpc_id arguments must be specified";

    $args{-device_index} =~ s/^eth//;
    
    my @param = $self->single_parm(InternetGatewayId=>\%args);
    push @param,$self->single_parm(VpcId=>\%args);
    return $self->call('AttachInternetGateway',@param);
}

=head2 $boolean = $ec2->detach_internet_gateway($internet_gateway_id,$vpc_id)

=head2 $boolean = $ec2->detach_internet_gateway(-internet_gateway_id => $id,
                                                -vpc_id              => $id)

This method detaches an internet gateway to a VPC.  You can use
internet gateway and VPC IDs, or their corresponding
VM::EC2::VPC::InternetGateway and VM::EC2::VPC objects.

Required arguments:

 -internet_gateway_id ID of the network interface to detach.
 -vpc_id              ID of the VPC to detach the gateway from.

On success, this method a true value.

Note that it may be more convenient to detach and detach gateways via
methods in the VM::EC2::VPC and VM::EC2::VPC::Gateway objects.

 $vpc->detach_internet_gateway($gateway);
 $gateway->detach($vpc);

=cut

sub detach_internet_gateway {
    my $self = shift;
    my %args; 
    if ($_[0] !~ /^-/ && @_ == 2) { 
	@args{qw(-internet_gateway_id -vpc_id)} = @_; 
    } else { 
	%args = @_;
    }
    $args{-internet_gateway_id} && $args{-vpc_id}
       or croak "-internet_gateway_id and-vpc_id arguments must be specified";

    $args{-device_index} =~ s/^eth//;
    
    my @param = $self->single_parm(InternetGatewayId=>\%args);
    push @param,$self->single_parm(VpcId=>\%args);
    return $self->call('DetachInternetGateway',@param);
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
