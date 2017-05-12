package VM::EC2::REST::elastic_network_interface;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateNetworkInterface            => 'fetch_one,networkInterface,VM::EC2::NetworkInterface',
    DeleteNetworkInterface            => 'boolean',
    DescribeNetworkInterfaces         => 'fetch_items,networkInterfaceSet,VM::EC2::NetworkInterface',
    ModifyNetworkInterfaceAttribute   => 'boolean',
    ResetNetworkInterfaceAttribute    => 'boolean',
    AttachNetworkInterface            => sub { shift->{attachmentId}    },
    DetachNetworkInterface            => 'boolean',
    );

=head1 NAME VM::EC2::REST::elastic_network_interface

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods create and manage Elastic Network Interfaces (ENI). Once
created, an ENI can be attached to instances and/or be associated with
a public IP address. ENIs can only be used in conjunction with VPC
instances.

Implemented:
 AttachNetworkInterface
 CreateNetworkInterface
 DeleteNetworkInterface
 DescribeNetworkInterfaceAttribute
 DescribeNetworkInterfaces
 DetachNetworkInterface
 ModifyNetworkInterfaceAttribute
 ResetNetworkInterfaceAttribute

Unimplemented:
 (none)

=head2 $interface = $ec2->create_network_interface($subnet_id)

=head2 $interface = $ec2->create_network_interface(%args)

This method creates an elastic network interface (ENI). If only a
single argument is provided, it is treated as the ID of the VPC subnet
to associate with the ENI. If multiple arguments are provided, they
are treated as -arg=>value parameter pairs.

Arguments:

The -subnet_id argument is mandatory. Others are optional.

 -subnet_id           --  ID of the VPC subnet to associate with the network
                           interface (mandatory)

 -private_ip_address  --  The primary private IP address of the network interface,
                           or a reference to an array of private IP addresses. In the
                           latter case, the first element of the array becomes the
                           primary address, and the subsequent ones become secondary
                           addresses. If no private IP address is specified, one will
                           be chosen for you. See below for more information on this
                           parameter.

 -private_ip_addresses -- Same as -private_ip_address, for readability.

 -secondary_ip_address_count -- An integer requesting this number of secondary IP
                          addresses to be allocated automatically. If present, 
                          cannot provide any secondary addresses explicitly.

 -description          -- Description of this ENI.

 -security_group_id    -- Array reference or scalar containing IDs of the security
                           group(s) to assign to this interface.

You can assign multiple IP addresses to the interface explicitly, or
by allowing EC2 to choose addresses within the designated subnet
automatically. The following examples demonstrate the syntax:

 # one primary address, chosen explicitly
 -private_ip_address => '192.168.0.12'

 # one primary address and two secondary addresses, chosen explicitly
 -private_ip_address => ['192.168.0.12','192.168.0.200','192.168.0.201'] 

 # one primary address chosen explicitly, and two secondaries chosen automatically
 -private_ip_address => ['192.168.0.12','auto','auto']

 # one primary address chosen explicitly, and two secondaries chosen automatically (another syntax)
 -private_ip_address => ['192.168.0.12',2]

 # one primary address chosen automatically, and two secondaries chosen automatically
 -private_ip_address => [auto,2]

You cannot assign some secondary addresses explicitly and others
automatically on the same ENI. If you provide no -private_ip_address
parameter at all, then a single private IP address will be chosen for
you (the same as -private_ip_address=>'auto').

The return value is a VM::EC2::NetworkInterface object

=cut

# NOTE: there is code overlap with network_interface_parm()
sub create_network_interface {
    my $self = shift;
    my %args = $self->args(-subnet_id=>@_);
    $args{-subnet_id} or croak "Usage: create_network_interface(-subnet_id=>\$id,\@more_args)";
    my   @parm = $self->single_parm('SubnetId',\%args);
    push @parm,  $self->single_parm('Description',\%args);
    push @parm,  $self->list_parm('SecurityGroupId',\%args);

    my $address   = $args{-private_ip_address} || $args{-private_ip_addresses};
    my $auto_count;

    if ($address) {
	my $c = 0;

	my @addresses = ref $address && ref $address eq 'ARRAY' ? @$address : ($address);
	my $primary   = shift @addresses;
	unless ($primary eq 'auto') {
	    push @parm, ("PrivateIpAddresses.$c.PrivateIpAddress" => $primary);
	    push @parm, ("PrivateIpAddresses.$c.Primary"          => 'true');
	}

	# deal with automatic secondary addresses .. this seems needlessly complex
	if (my @auto = grep {/auto/i} @addresses) {
	    @auto == @addresses or croak "cannot request both explicit and automatic secondary IP addresses";
	    $auto_count = @auto;
	}
	$auto_count = $addresses[0] if @addresses == 1 && $addresses[0] =~ /^\d+$/;
	$auto_count ||= $args{-secondary_ip_address_count};
	
	unless ($auto_count) {
	    foreach (@addresses) {
		$c++;
		push @parm,("PrivateIpAddresses.$c.PrivateIpAddress" => $_     );
		push @parm,("PrivateIpAddresses.$c.Primary"          => 'false');
	    }
	}
    }
    push @parm,('SecondaryPrivateIpAddressCount'=>$auto_count) if $auto_count ||= $args{-secondary_ip_address_count};

    $self->call('CreateNetworkInterface',@parm);
}

=head2 $result = $ec2->delete_network_interface($network_interface_id);

=head2 $result = $ec2->delete_network_interface(-network_interface_id => $id);

Deletes the specified network interface. Returns a boolean indicating
success of the delete operation.

=cut

sub delete_network_interface {
    my $self = shift;
    my %args  = $self->args(-network_interface_id => @_);
    my @param = $self->single_parm(NetworkInterfaceId=>\%args);
    return $self->call('DeleteNetworkInterface',@param);
}

=head2 @ifs = $ec2->describe_network_interfaces(@interface_ids)

=head2 @ifs = $ec2->describe_network_interfaces(\%filters)

=head2 @ifs = $ec2->describe_network_interfaces(-network_interface_id=>\@interface_ids,-filter=>\%filters)

Return a list of elastic network interfaces as
VM::EC2::VPC::NetworkInterface objects. You may restrict the list by
passing a list of network interface IDs, a hashref of filters or by
using the full named-parameter form.

Optional arguments:

 -network_interface_id    A single network interface ID or an arrayref to
                           a list of IDs.

 -filter                  A hashref for filtering on tags and other attributes.

The list of valid filters can be found at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkInterfaces.html.

=cut

sub describe_network_interfaces {
    my $self = shift;
    my %args = $self->args(-network_interface_id=>@_);
    my @params = $self->list_parm('NetworkInterfaceId',\%args);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeNetworkInterfaces',@params);
}

=head2 @data = $ec2->describe_network_interface_attribute($network_id,$attribute)

This method returns network interface attributes. Only one attribute
can be retrieved at a time. The following is the list of attributes
that can be retrieved:

 description           -- hashref
 groupSet              -- hashref
 sourceDestCheck       -- hashref
 attachment            -- hashref

These values can be retrieved more conveniently from the
L<VM::EC2::NetworkInterface> object, so there is no attempt to parse
the results of this call into Perl objects.

=cut

sub describe_network_interface_attribute {
    my $self = shift;
    @_ == 2 or croak "Usage: describe_network_interface_attribute(\$interface_id,\$attribute_name)";
    my ($interface_id,$attribute) = @_;
    my @param  = (NetworkInterfaceId=>$interface_id,Attribute=>$attribute);
    my $result = $self->call('DescribeNetworkInterfaceAttribute',@param);
    return $result && $result->attribute($attribute);
}

=head2 $boolean = $ec2->modify_network_interface_attribute($interface_id,-$attribute_name=>$value)

This method changes network interface attributes. Only one attribute can be set per call
The following is the list of attributes that can be set:

 -description             -- interface description
 -security_group_id       -- single security group ID or arrayref to a list of group ids
 -source_dest_check       -- boolean; if false enables packets to be forwarded, and is necessary
                               for NAT and other router tasks
 -delete_on_termination   -- [$attachment_id=>$delete_on_termination]; Pass this a two-element
                               array reference consisting of the attachment ID and a boolean 
                               indicating whether deleteOnTermination should be enabled for
                               this attachment.
=cut

sub modify_network_interface_attribute {
    my $self = shift;
    my $interface_id = shift or croak "Usage: modify_network_interface_attribute(\$interfaceId,%param)";
    my %args   = @_;
    my @param  = (NetworkInterfaceId=>$interface_id);
    push @param,$self->value_parm($_,\%args) foreach qw(Description SourceDestCheck);
    push @param,$self->list_parm('SecurityGroupId',\%args);
    if (my $dot = $args{-delete_on_termination}) {
	my ($attachment_id,$delete_on_termination) = @$dot;
	push @param,'Attachment.AttachmentId'=>$attachment_id;
	push @param,'Attachment.DeleteOnTermination'=>$delete_on_termination ? 'true' : 'false';
    }
    return $self->call('ModifyNetworkInterfaceAttribute',@param);
}

=head2 $boolean = $ec2->reset_network_interface_attribute($interface_id => $attribute_name)

This method resets the named network interface attribute to its
default value. Only one attribute can be reset per call. The AWS
documentation is not completely clear on this point, but it appears
that the only attribute that can be reset using this method is:

 source_dest_check       -- Turns on source destination checking 

For consistency with modify_network_interface_attribute, you may
specify attribute names with or without a leading dash, and using
either under_score or mixedCase naming:

 $ec2->reset_network_interface_atribute('eni-12345678' => 'source_dest_check');
 $ec2->reset_network_interface_atribute('eni-12345678' => '-source_dest_check');
 $ec2->reset_network_interface_atribute('eni-12345678' => sourceDestCheck);

=cut

sub reset_network_interface_attribute {
    my $self = shift;
    @_ == 2 or croak "Usage: reset_network_interface_attribute(\$interfaceId,\$attribute)";
    my ($interface_id,$attribute) = @_;

    $attribute = s/^-//;
    $attribute = $self->uncanonicalize($attribute);
    my @param = (NetworkInterfaceId=> $interface_id,
		 Attribute         => $attribute
	);
    return $self->call('ResetNetworkInterfaceAttribute',@param);
}

=head2 $attachmentId = $ec2->attach_network_interface($network_interface_id,$instance_id,$device_index)

=head2 $attachmentId = $ec2->attach_network_interface(-network_interface_id => $id,
                                                      -instance_id          => $id,
                                                      -device_index         => $index)

This method attaches a network interface to an instance using the
indicated device index. You can use instance and network interface
IDs, or VM::EC2::Instance and VM::EC2::NetworkInterface objects. You
may use an integer for -device_index, or use the strings "eth0",
"eth1" etc.

Required arguments:

 -network_interface_id ID of the network interface to attach.
 -instance_id          ID of the instance to attach the interface to.
 -device_index         Network device number to use (e.g. 0 for eth0).

On success, this method returns the attachmentId of the new attachment
(not a VM::EC2::NetworkInterface::Attachment object, due to an AWS API
inconsistency).

Note that it may be more convenient to attach and detach network
interfaces via methods in the VM::EC2::Instance and
VM::EC2::NetworkInterface objects:

 $instance->attach_network_interface($interface=>'eth0');
 $interface->attach($instance=>'eth0');

=cut

sub attach_network_interface {
    my $self = shift;
    my %args; 
    if ($_[0] !~ /^-/ && @_ == 3) { 
	@args{qw(-network_interface_id -instance_id -device_index)} = @_; 
    } else { 
	%args = @_;
    }
    $args{-network_interface_id} && $args{-instance_id} && defined $args{-device_index} or
	croak "-network_interface_id, -instance_id and -device_index arguments must all be specified";

    $args{-device_index} =~ s/^eth//;
    
    my @param = $self->single_parm(NetworkInterfaceId=>\%args);
    push @param,$self->single_parm(InstanceId=>\%args);
    push @param,$self->single_parm(DeviceIndex=>\%args);
    return $self->call('AttachNetworkInterface',@param);
}

=head2 $boolean = $ec2->detach_network_interface($attachment_id [,$force])

This method detaches a network interface from an instance. Both the
network interface and instance are specified using their
attachmentId. If the $force flag is present, and true, then the
detachment will be forced even if the interface is in use.

Note that it may be more convenient to attach and detach network
interfaces via methods in the VM::EC2::Instance and
VM::EC2::NetworkInterface objects:

 $instance->detach_network_interface($interface);
 $interface->detach();

=cut

sub detach_network_interface {
    my $self = shift;
    my ($attachment_id,$force) = @_;
    $attachment_id or croak "Usage: detach_network_interface(\$attachment_id [,\$force])";
    my @param = (AttachmentId => $attachment_id);
    push @param,(Force => 'true') if defined $force && $force;
    return $self->call('DetachNetworkInterface',@param);
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
