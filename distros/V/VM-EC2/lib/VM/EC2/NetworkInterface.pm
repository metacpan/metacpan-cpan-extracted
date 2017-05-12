package VM::EC2::NetworkInterface;

=head1 NAME

VM::EC2::NetworkInterface - Object describing an Amazon Elastic Network Interface (ENI)

=head1 SYNOPSIS

  use VM::EC2;
  my $ec2 = VM::EC2->new(...);
  my $interface = $ec2->describe_network_interfaces('eni-12345');
  print $interface->subNetId,"\n",
        $interface->description,"\n",
        $interface->vpcId,"\n",
        $interface->status,"\n",
        $interface->privateIpAddress,"\n",
        $interface->macAddress,"\n";
  
=head1 DESCRIPTION

This object provides access to information about Amazon Elastic
Network Interface objects, which are used in conjunction with virtual
private cloud (VPC) instances to create multi-homed web servers,
routers, firewalls, and so forth.

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 networkInterfaceId       -- The ID of this ENI
 subnetId                 -- The ID of the subnet this ENI belongs to
 vpcId                    -- The ID of the VPC this ENI belongs to
 ownerId                  -- Owner of the ENI
 status                   -- ENI status, one of "available" or "in-use"
 privateIpAddress         -- Primary private IP address of the ENI
 privateDnsName           -- Primary private DNS name of the ENI
                             as a set of VM::EC2::Group objects.
 attachment               -- Information about the attachment of this ENI to
                             an instance, as a VM::EC2::NetworkInterface::Attachment
                             object.
 association              -- Information about the association of this ENI with
                             an elastic public IP address.
 privateIpAddresses       -- List of private IP addresses assigned to this ENI,
                             as a list of VM::EC2::NetworkInterface::PrivateIpAddress
                             objects.
 availabilityZone         -- Availability zone for this ENI as a VM::EC2::AvailabilityZone
                             object.
 macAddress               -- MAC address for this interface.

In addition, this object supports the following convenience methods:

 resetAttributes()          -- Return attributes to their default states. Currently only
                               sets the SourceDestCheck value to true.

 description([$new_value])  -- Description of the ENI. Pass a single argument to set a new
                               description

 sourceDestCheck([$boolean])-- Boolean value. If true, prevent this ENI from
                               forwarding packets between subnets. Value can optionally
                               be set

 security_groups([@new_groups]) -- List of security groups this ENI belongs to. Pass a
                               list of new security groups to change this value.

 delete_on_termination([$boolean])
                            -- Whether the deleteOnTermination flag is set for the current
                               attachment. Pass a boolean value to change the value.

=head1 Attaching to an instance

The following methods allow the interface to be attached to, and
detached from, instances.

=head2 $attachment_id = $interface->attach($instance_id => $device)

=head2 $attachment_id = $interfacee->attach(-instance_id    => $id,
                                            -device_index   => $device)

This method attaches the network interface an instance using the the
indicated device index. You can provide either an instance ID, or a
VM::EC2::Instance object. You may use an integer for -device_index, or
use the strings "eth0", "eth1" etc.

Required arguments:

 -instance_id          ID of the instance to attach to.
 -device_index         Network device number to use (e.g. 0 for eth0).

On success, this method returns the attachmentId of the new attachment
(not a VM::EC2::NetworkInterface::Attachment object, due to an AWS API
inconsistency).

=head2 $boolean = $interface->detach([$force])

This method detaches the network interface from whatever instance it
is currently attached to. If a true argument is provided, then the
detachment will be forced, even if the interface is in use.

On success, this method returns a true value.

=head1 Adding IP addresses

=head2 $result = $interface->assign_private_ip_addresses(@addresses)

=head2 $result = $interface->assign_private_ip_addresses(%args)

Assign one or more secondary private IP addresses to the network
interface. You can either set the addresses explicitly, or provide a
count of secondary addresses, and let Amazon select them for you.

In the list argument form, pass a list of desired IP addresses, or a
count of the number of addresses to select for you:

 $interface->assign_private_ip_addresses(3);  # three automatic addresses
 $interface->assign_private_ip_addresses('192.168.0.10','192.168.0.11');

Required arguments:

 -private_ip_address      One or more secondary IP addresses, as a scalar string
 -private_ip_addresses    or array reference. (The two arguments are equivalent).

Optional arguments:

 -allow_reassignment      If true, allow assignment of an IP address is already in
                          use by another network interface or instance.

The following are valid arguments to -private_ip_address:

 -private_ip_address => '192.168.0.12'                    # single address
 -private_ip_address => ['192.168.0.12','192.168.0.13]    # multiple addresses
 -private_ip_address => 3                                 # autoselect three addresses

The mixed form of address, such as ['192.168.0.12','auto'] is not allowed in this call.

On success, this method returns true.

=head2 $result = $interface->unassign_private_ip_addresses(@addresses)

=head2 $result = $interface->unassign_private_ip_addresses(-private_ip_address => \@addresses)

Unassign one or more secondary private IP addresses from the network
interface.

In the list argument form, pass a list of desired IP addresses to unassign.

 $interface->assign_private_ip_addresses('192.168.0.10','192.168.0.11');

In the named argument form, use:

 -private_ip_address      One or more secondary IP addresses, as a scalar string
 -private_ip_addresses    or array reference. (The two arguments are equivalent).

The following are valid arguments to -private_ip_address:

 -private_ip_address => '192.168.0.12'                    # single address
 -private_ip_address => ['192.168.0.12','192.168.0.13]    # multiple addresses

On success, this method returns true.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
networkInterfaceId

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::NetworkInterface>
L<VM::EC2::NetworkInterface::Attachment>
L<VM::EC2::NetworkInterface::Association>

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
use VM::EC2::Group;
use VM::EC2::NetworkInterface::PrivateIpAddress;
use VM::EC2::NetworkInterface::Attachment;
use VM::EC2::NetworkInterface::Association;

sub valid_fields {
    my $self  = shift;
    return qw(networkInterfaceId subnetId vpcId description ownerId status privateIpAddress privateDnsName
              sourceDestCheck groupSet attachment association privateIpAddressesSet macAddress requesterManaged
              availabilityZone);
}

sub refresh {
    my $self = shift;
    my $i    = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_network_interfaces(-network_interface_id=>$self->networkInterfaceId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

sub current_status {
    my $self = shift;
    $self->refresh;
    $self->status;
}

sub primary_id {shift->networkInterfaceId}

sub groups {
    my $self = shift;
    my $groupSet = $self->SUPER::groupSet;
    return map {VM::EC2::Group->new($_,$self->aws,$self->xmlns,$self->requestId)}
        @{$groupSet->{item}};
}

sub privateIpAddresses {
    my $self = shift;
    my $set  = $self->SUPER::privateIpAddressesSet;
    return map {VM::EC2::NetworkInterface::PrivateIpAddress->new($_,$self->aws)} @{$set->{item}};
}

sub attachment {
    my $self = shift;
    my $a    = $self->SUPER::attachment or return;
    return VM::EC2::NetworkInterface::Attachment->new($a,$self->aws);
}

sub association {
    my $self = shift;
    my $a    = $self->SUPER::association or return;
    return VM::EC2::NetworkInterface::Association->new($a,$self->aws);
}

sub vpc {
    my $self = shift;
    return $self->describe_vpcs($self->vpcId);
}

# get/set methods
sub description {
    my $self = shift;
    my $d    = $self->aws->describe_network_interface_attribute($self,'description');
    $self->aws->modify_network_interface_attribute($self,-description=>shift) if @_;
    return $d;
}

sub security_groups {
    my $self = shift;
    my @d    = $self->aws->describe_network_interface_attribute($self,'groupSet');
    $self->aws->modify_network_interface_attribute($self,-security_group_id=>\@_) if @_;
    return map {VM::EC2::Group->new($_,$self->aws)} @d;
}

sub source_dest_check {
    my $self = shift;
    my $d    = $self->aws->describe_network_interface_attribute($self,'sourceDestCheck');
    $self->aws->modify_network_interface_attribute($self,-source_dest_check=>(shift() ? 'true' : 'false')) if @_;    
    return $d eq 'true';
}

sub reset_attributes {
    my $self = shift;
    return $self->aws->reset_network_interface_attribute($self=>'sourceDestCheck');
}

sub delete_on_termination {
    my $self = shift;
    my $d    = $self->aws->describe_network_interface_attribute($self,'attachment') or return;
    my $att  = VM::EC2::NetworkInterface::Attachment->new($d,$self->aws);
    $self->aws->modify_network_interface_attribute($self,-delete_on_termination=>[$att=>shift]) if @_;
    return $att->delete_on_termination;
}

sub availabilityZone {
    my $self = shift;
    my $z    = $self->SUPER::availabilityZone or return;
    return $self->aws->describe_availability_zones($z);
}

sub attach { 
    my $self = shift;
    my %args;
    if (@_==2 && $_[0] !~ /^-/) {
	@args{qw(-instance_id -device_index)} = @_; 
    } else {
	%args = @_;
    }
    $args{-instance_id} && $args{-device_index}
       or croak "usage: \$interface->attach(\$instance_id,\$device_index)";
    $args{-network_interface_id} = $self->networkInterfaceId;
    my $result = $self->aws->attach_network_interface(%args);
    $self->refresh if $result;
    eval {$args{-instance_id}->refresh} if $result;
    return $result;
}

sub detach {
    my $self = shift;
    my $force = shift;
    my $attachment = $self->attachment;
    $attachment or croak "$self is not attached";
    my $result =  $self->aws->detach_network_interface($attachment,$force);
    $self->refresh if $result;
    return $result;
}

sub assign_private_ip_addresses {
    my $self = shift;
    my %args;
    if (@_ && $_[0] !~ /^-/) {
	%args = (-private_ip_address => @_==1 ? $_[0] : \@_);
    } else {
	%args = @_;
    }
    my $result = $self->aws->assign_private_ip_addresses(-network_interface_id=>$self,%args);
    $self->refresh if $result;
    return $result;
}

sub unassign_private_ip_addresses {
    my $self = shift;
    my %args;
    if (@_ && $_[0] !~ /^-/) {
	%args = (-private_ip_address => \@_);
    } else {
	%args = @_;
    }
    my $result = $self->aws->unassign_private_ip_addresses(-network_interface_id=>$self,%args);
    $self->refresh if $result;
    return $result;
}

1;

