package VM::EC2::Instance;

=head1 NAME

VM::EC2::Instance - Object describing an Amazon EC2 instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instances(-instance_id=>'i-12345');

  $instanceId    = $instance->instanceId;
  $ownerId       = $instance->ownerId;
  $reservationId = $instance->reservationId;
  $imageId       = $instance->imageId;
  $state         = $instance->instanceState;
  @groups        = $instance->groups;
  $private_ip    = $instance->privateIpAddress;
  $public_ip     = $instance->ipAddress;
  $private_dns   = $instance->privateDnsName;
  $public_dns    = $instance->dnsName;
  $time          = $instance->launchTime;
  $status        = $instance->current_status;
  $tags          = $instance->tags;

  $stateChange = $instance->start();
  $stateChange = $instance->stop();
  $stateChange = $instance->reboot();
  $stateChange = $instance->terminate();

  $seconds       = $instance->up_time;

=head1 DESCRIPTION

This object represents an Amazon EC2 instance, and is returned by
VM::EC2->describe_instances(). In addition to methods to query the
instance's attributes, there are methods that allow you to manage the
instance's lifecycle, including start, stopping, and terminating it.

Note that the information about security groups and reservations that
is returned by describe_instances() is copied into each instance
before returning it, so there is no concept of a "reservation set" in
this interface.

=head1 METHODS

These object methods are supported:
 
 instanceId     -- ID of this instance.

 imageId        -- ID of the image used to launch this instance.

 instanceState  -- The current state of the instance at the time
                   that describe_instances() was called, as a
                   VM::EC2::Instance::State object. Also
                   see the status() method, which re-queries EC2 for
                   the current state of the instance. States are
                   represented in strings as  "terminated", "running", 
                   "stopped", "stopping",and "shutting-down".

 privateDnsName -- The private DNS name assigned to the instance within
                   Amazon's EC2 network. This element is defined only
                   for running instances.

 dnsName        -- The public DNS name assigned to the instance, defined
                   only for running instances.

 reason         -- Reason for the most recent state transition, 
                   if applicable.

 keyName        -- Name of the associated key pair, if applicable.

 keyPair        -- The VM::EC2::KeyPair object, derived from the keyName

 amiLaunchIndex -- The AMI launch index, which can be used to find
                   this instance within the launch group.

 productCodes   -- A list of product codes that apply to this instance.

 instanceType   -- The instance type, such as "t1.micro". CHANGEABLE.

 launchTime     -- The time the instance launched.

 placement      -- The placement of the instance. Returns a
                   VM::EC2::Instance::Placement object, which when used
                   as a string is equal to the instance's
                   availability zone.

 availabilityZone -- Same as placement.

 kernelId       -- ID of the instance's kernel. CHANGEABLE.

 ramdiskId      -- ID of the instance's RAM disk. CHANGEABLE.

 platform       -- Platform of the instance, either "windows" or empty.

 monitoring     -- State of monitoring for the instance. One of 
                   "disabled", "enabled", or "pending". CHANGEABLE:
                   pass true or "enabled" to turn on monitoring. Pass
                   false or "disabled" to turn it off.

 subnetId       -- The Amazon VPC subnet ID in which the instance is 
                   running, for Virtual Private Cloud instances only.

 vpcId          -- The Virtual Private Cloud ID for VPC instances.

 privateIpAddress -- The private (internal Amazon) IP address assigned
                   to the instance.

 ipAddress      -- The public IP address of the instance.

 sourceDestCheck -- Whether source destination checking is enabled on
                   this instance. This returns a Perl boolean rather than
                   the string "true". This method is used in conjunction
                   with VPC NAT functionality. See the Amazon VPC User
                   Guide for details. CHANGEABLE.

 networkInterfaceSet -- Return list of VM::EC2::ElasticNetworkInterface objects
                   attached to this instance.

 iamInstanceProfile -- The IAM instance profile (IIP) associated with this instance.

 ebsOptimized       -- True if instance is optimized for EBS I/O.

 groupSet       -- List of VM::EC2::Group objects indicating the VPC
                   security groups in which this instance resides. Not to be
                   confused with groups(), which returns the security groups
                   of non-VPC instances. 

 stateReason    -- A VM::EC2::Instance::State::Reason object which
                   indicates the reason for the instance's most recent
                   state change. See http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-ItemType-StateReasonType.html

 architecture   -- The architecture of the image. Either "i386" or "x86_64".

 rootDeviceType -- The type of the root device used by the instance. One of "ebs"
                   or "instance-store".

 rootDeviceName -- The name of the the device used by the instance, such as /dev/sda1.
                   CHANGEABLE.

 blockDeviceMapping -- The block device mappings for the instance, represented
                   as a list of L<VM::EC2::BlockDevice::Mapping> objects.

 instanceLifeCycle -- "spot" if this instance is a spot instance, otherwise empty.

 spotInstanceRequestId -- The ID of the spot instance request, if applicable.

 virtualizationType -- Either "paravirtual" or "hvm".

 clientToken    -- The idempotency token provided at the time of the AMI launch,
                   if any.

 hypervisor     -- The instance's hypervisor type, either "ovm" or "xen".

 userData       -- User data passed to instance at launch. CHANGEABLE.

 disableApiTermination -- True if the instance is protected from termination
                   via the console or command-line APIs. CHANGEABLE.

 instanceInitiatedShutdownBehavior -- Action to take when the instance calls
                   shutdown or halt. One of "stop" or "terminate". CHANGEABLE.

 sriovNetSupport -- Specifies whether enhanced networking is enabled.  "simple" if so.

 tagSet         -- Tags for the instance as a hashref. CHANGEABLE via add_tags()
                   and delete_tags().

The object also supports the tags() method described in
L<VM::EC2::Generic>:

 print "ready for production\n" if $image->tags->{Released};

All methods return read-only values except for those marked CHANGEABLE
in the list above. For these, you can change the instance attribute on
stopped instances by invoking the method with an appropriate new
value. For example, to change the instance type from "t1.micro" to
"m1.small", you can do this:

 my @tiny_instances = $ec2->describe_instances(-filter=>{'instance-type'=>'t1.micro'});
 for my $i (@tiny_instances) {
    next unless $i->instanceState eq 'stopped';
    $i->instanceType('m1.small') or die $ec2->error;
 }

When you attempt to change an attribute of an instance, the method
will return true on success, false on failure. On failure, the
detailed error messages can be recovered from the VM::EC2 object's
error() method.

=head1 LIFECYCLE METHODS

In addition, the following convenience functions are provided

=head2 $state = $instance->current_status

This method queries AWS for the instance's current state and returns
it as a VM::EC2::Instance::State object. This enables you to 
poll the instance until it is in the desired state:

 while ($instance->current_status eq 'pending') { sleep 5 }

=head2 $state = $instance->current_state

An alias for current_status().

=head2 $state_change = $instance->start([$wait])

This method will start the current instance and returns a
VM::EC2::Instance::State::Change object that can be used to
monitor the status of the instance. By default the method returns
immediately, but you can pass a true value as an argument in order to
pause execution until the instance is in the "running" state.

Here's a polling example:

  $state = $instance->start;
  while ($state->status eq 'pending') { sleep 5 }

Here's an example that will pause until the instance is running:

  $instance->start(1);

Attempting to start an already running instance, or one that is
in transition, will throw a fatal error.

=head2 $state_change = $instance->stop([$wait])

This method is similar to start(), except that it can be used to
stop a running instance.

=head2 $state_change = $instance->terminate([$wait])

This method is similar to start(), except that it can be used to
terminate an instance. It can only be called on instances that
are either "running" or "stopped".

=head2 $state_change = $instance->reboot()

Reboot the instance. Rebooting doesn't occur immediately; instead the
request is queued by the Amazon system and may be satisfied several
minutes later. For this reason, there is no "wait" argument.

=head2 $seconds = $instance->up_time()

Return the number of seconds since the instance was launched. Note
that this includes time that the instance was either in the "running"
or "stopped" state.

=head2 $result = $instance->associate_address($elastic_address)

Associate an elastic address with this instance. If you are
associating a VPC elastic IP address with the instance, the result
code will indicate the associationId. Otherwise it will be a simple
perl truth value ("1") if successful, undef if false.

In the case of an ordinary EC2 Elastic IP address, the first argument may
either be an ordinary string (xx.xx.xx.xx format) or a
VM::EC2::ElasticAddress object. However, if it is a VPC elastic
IP address, then the argument must be a VM::EC2::ElasticAddress
as returned by describe_addresses(). The reason for this is that the
allocationId must be retrieved from the object in order to use in the
call.

=head2 $bool = $instance->disassociate_address

Disassociate an elastic IP address from this instance. if any. The
result will be true if disassociation was successful. Note that for a
short period of time (up to a few minutes) after disassociation, the
instance will have no public IP address and will be unreachable from
the internet.

=head2 @list = $instance->network_interfaces

Return the network interfaces attached to this instance as a set of
VM::EC2::NetworkInterface objects (VPC only).

=head2 $instance->refresh

This method will refresh the object from AWS, updating all values to
their current ones. You can call it after starting an instance in
order to get its IP address. Note that refresh() is called
automatically for you if you call start(), stop() or terminate() with
a true $wait argument.

=head2 $text = $instance->console_output

Return the console output of the instance as a
VM::EC2::ConsoleOutput object. This object can be treated as a
string, or as an object with methods

=head1 CREATING IMAGES

The create_image() method provides a handy way of creating and
registering an AMI based on the current state of the instance. All
currently-associated block devices will be snapshotted and associated
with the image.

Note that this operation can take a long time to complete. You may
follow its progress by calling the returned image object's
current_status() method.

=head2 $imageId = $instance->create_image($name [,$description])

=head2 $imageId = $instance->create_image(-name=>$name,-description=>$description,-no_reboot=>$boolean)

Create an image from this instance and return a VM::EC2::Image object.
The instance must be in the "stopped" or "running" state. In the
latter case, Amazon will stop the instance, create the image, and then
restart it unless the -no_reboot argument is provided.

Arguments:

 -name           Name for the image that will be created. (required)
 -description    Description of the new image.
 -no_reboot      If true, don't reboot the instance.

In the unnamed argument version you can provide the name and
optionally the description of the resulting image.

=head2 $boolean = $instance->confirm_product_code($product_code)

Return true if this instance is associated with the given product code.

=head1 VOLUME MANAGEMENT

=head2 $attachment = $instance->attach_volume($volume_id,$device)

=head2 $attachment = $instance->attach_volume(-volume_id=>$volume_id,-device=>$device)

Attach volume $volume_id to this instance using virtual device
$device. Both arguments are required. The result is a
VM::EC2::BlockDevice::Attachment object which you can monitor by
calling current_status():

    my $a = $instance->attach_volume('vol-12345'=>'/dev/sdg');
    while ($a->current_status ne 'attached') {
       sleep 2;
    }
    print "volume is ready to go\n";

=head2 $attachment = $instance->detach_volume($vol_or_device)

=head2 $attachment = $instance->detach_volume(-volume_id => $volume_id
                                              -device    => $device,
                                              -force     => $force);

Detaches the specified volume. In the single-argument form, you may
provide either a volume or a device name. In the named-argument form,
you may provide both the volume and the device as a check that you are
detaching exactly the volume you think you are.

Optional arguments:

 -volume_id      -- ID of the instance to detach from.
 -device         -- How the device is exposed to the instance.
 -force          -- Force detachment, even if previous attempts were
                    unsuccessful.

The result is a VM::EC2::BlockDevice::Attachment object which
you can monitor by calling current_status():

    my $a = $instance->detach_volume('/dev/sdg');
    while ($a->current_status ne 'detached') {
       sleep 2;
    }
    print "volume is ready to go\n";

=head1 NETWORK INTERFACE MANAGEMENT

=head2 $attachment_id = $instance->attach_network_interface($interface_id => $device)

=head2 $attachment_id = $instance->attach_network_interface(-network_interface_id=>$id,
                                                            -device_index   => $device)

This method attaches a network interface to the current instance using
the indicated device index. You can use either an elastic network
interface ID, or a VM::EC2::NetworkInterface object. You may use an
integer for -device_index, or use the strings "eth0", "eth1" etc.

Required arguments:

 -network_interface_id ID of the network interface to attach.
 -device_index         Network device number to use (e.g. 0 for eth0).

On success, this method returns the attachmentId of the new attachment
(not a VM::EC2::NetworkInterface::Attachment object, due to an AWS API
inconsistency).

=head2 $boolean = $instance->detach_network_interface($interface_id [,$force])

This method detaches a network interface from the current instance. If
a true second argument is provided, then the detachment will be
forced, even if the interface is in use.

On success, this method returns a true value.

=head1 ACCESSING INSTANCE METADATA

=head2 $meta = $instance->metadata

B<For use on running EC2 instances only:> This method returns a
VM::EC2::Instance::Metadata object that will return information about
the currently running instance using the HTTP:// metadata fields
described at
http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?instancedata-data-categories.html. This
is usually fastest way to get runtime information on the current
instance.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
instanceId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::Instance::State>
L<VM::EC2::Instance::State::Reason>
L<VM::EC2::Instance::Metadata>
L<VM::EC2::Instance::Placement>
L<VM::EC2::Tag>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::Group;
use VM::EC2::Instance::State;
use VM::EC2::Instance::State::Reason;
use VM::EC2::BlockDevice::Mapping;
use VM::EC2::NetworkInterface;
use VM::EC2::Instance::Placement;
use VM::EC2::ProductCode;
use VM::EC2::Instance::IamProfile;
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp 'croak';

sub new {
    my $self = shift;
    my %args = @_;
    return bless {
	data        => $args{-instance},
	reservation => $args{-reservation},
	requester   => $args{-requester},
	owner       => $args{-owner},
	groups      => $args{-groups},
	aws         => $args{-aws},
	xmlns       => $args{-xmlns},
	requestId   => $args{-requestId},
    },ref $self || $self;
}

sub reservationId {shift->{reservation} }
sub requesterId   {shift->{requester}   }
sub ownerId       {shift->{owner}       }
sub groups        {
    my $self = shift;
    my $groups = $self->{groups};
    if (@_) {
	return $self->aws->modify_instance_attribute($self,-group_id=>\@_);
    } else {
	return @$groups;
    }
}
sub group         {shift()->{groups}[0] }
sub primary_id    {shift()->instanceId  }

sub valid_fields {
    my $self  = shift;
    return qw(instanceId
              imageId
              instanceState
              privateDnsName
              dnsName
              reason
              keyName
              amiLaunchIndex
              productCodes
              instanceType
              launchTime
              placement
              kernelId
              ramdiskId
              platform
              monitoring
              subnetId
              vpcId
              privateIpAddress
              ipAddress
              sourceDestCheck
              networkInterfaceSet
              iamInstanceProfile
              ebsOptimized
              groupSet
              stateReason
              architecture
              rootDeviceType
              rootDeviceName
              blockDeviceMapping
              instanceLifeCycle
              spotInstanceRequestId
              virtualizationType
              clientToken
              hypervisor
              tagSet
              sriovNetSupport
             );
}

sub keyPair {
    my $self = shift;
    my $name = $self->keyName or return;
    return $self->aws->describe_key_pairs($name);
}

sub instanceState {
    my $self = shift;
    my $state = $self->SUPER::instanceState;
    return VM::EC2::Instance::State->new($state);
}

sub sourceDestCheck {
    my $self = shift;
    my $check = $self->SUPER::sourceDestCheck;
    if (@_) {
	my $c = shift() ? 'true' : 'false';
	return $self->aws->modify_instance_attribute($self,-source_dest_check=>$c);
    }
    return $check eq 'true';
}

sub ebsOptimized {
    my $self = shift;
    my $opt  = $self->SUPER::ebsOptimized;
    return $opt eq 'true';
}

sub groupSet {
    my $self = shift;
    my $groupSet = $self->SUPER::groupSet;
    return map {VM::EC2::Group->new($_,$self->aws,$self->xmlns,$self->requestId)}
        @{$groupSet->{item}};
}

sub placement {
    my $self = shift;
    my $p = $self->SUPER::placement or return;
    return VM::EC2::Instance::Placement->new($p,$self->aws,$self->xmlns,$self->requestId);
}

sub availabilityZone { shift->placement }

sub monitoring {
    my $self = shift;
    if (@_) {
	my $enable = shift;
	if ($enable && $enable ne 'disabled') {
	    return $self->aws->monitor_instances($self);
	} else {
	    return $self->aws->unmonitor_instances($self);
	}
    }
    return $self->SUPER::monitoring->{state};
}

sub blockDeviceMapping {
    my $self = shift;
    $self->refresh;
    my $mapping = $self->SUPER::blockDeviceMapping or return;
    my @mapping = map { VM::EC2::BlockDevice::Mapping->new($_,$self->aws)} @{$mapping->{item}};
    foreach (@mapping) { $_->instance($self) }
    return @mapping;
}

sub blockDeviceMappings {shift->blockDeviceMapping}

sub stateReason {
    my $self = shift;
    my $reason = $self->SUPER::stateReason;
    return VM::EC2::Instance::State::Reason->new($reason,$self->_object_args);
}

sub kernelId {
    my $self = shift;
    my $kernel = $self->SUPER::kernelId;
    if (@_) {
	return $self->aws->modify_instance_attribute($self,-kernel=>shift());
    } else {
	return $kernel;
    }
}

sub ramdiskId {
    my $self = shift;
    my $ramdisk = $self->SUPER::ramdiskId;
    if (@_) {
	return $self->aws->modify_instance_attribute($self,-ramdisk=>shift());
    } else {
	return $ramdisk;
    }
}

sub rootDeviceName {
    my $self = shift;
    my $root = $self->SUPER::rootDeviceName;
    if (@_) {
	return $self->aws->modify_instance_attribute($self,-root_device_name => shift());
    } else {
	return $root;
    }
}

sub instanceType {
    my $self = shift;
    return $self->aws->modify_instance_attribute($self, 
						-instance_type=>shift()) if @_;
    return $self->SUPER::instanceType;
}

sub userData {
    my $self = shift;

    if (@_) {
	my $encoded = encode_base64(shift);
	return $self->aws->modify_instance_attribute($self,-user_data=>$encoded);
    }

    my $data = $self->aws->describe_instance_attribute($self,'userData') or return;
    VM::EC2::Dispatch::load_module('MIME::Base64');
    return decode_base64($data);
}

sub disableApiTermination {
    my $self = shift;
    return $self->aws->modify_instance_attribute($self, 
						-disable_api_termination=>shift()) if @_;
    return $self->aws->describe_instance_attribute($self,'disableApiTermination') eq 'true';
}

sub instanceInitiatedShutdownBehavior {
    my $self = shift;
    return $self->aws->modify_instance_attribute($self, 
						-shutdown_behavior=>shift()) if @_;
    return $self->aws->describe_instance_attribute($self,'instanceInitiatedShutdownBehavior');
}

sub networkInterfaceSet {
    my $self = shift;
    my $set  = $self->SUPER::networkInterfaceSet or return;
    return map {VM::EC2::NetworkInterface->new($_,$self->aws)} @{$set->{item}};
}

sub network_interfaces { shift->networkInterfaceSet }

sub iamInstanceProfile {
    my $self = shift;
    my $profile = $self->SUPER::iamInstanceProfile or return;
    return VM::EC2::Instance::IamProfile->new($profile,$self->aws);
}

sub current_status {
    my $self = shift;
    my $retry = 0;
    until ($self->refresh) {
        if (++$retry > 10) {
            croak "invalid instance: ",$self->instanceId;
	}
        sleep 2;
    }
    return $self->instanceState;
}

sub current_status_async {
    my $self = shift;
    my $to_caller = VM::EC2->condvar;

    my $cv = $self->aws->describe_instances_async(-instance_id=>$self->instanceId);

    $cv->cb(sub {
	my $i = shift->recv;
	$to_caller->send($i->instanceState)
	    });

    return $to_caller;
}

sub current_state { shift->current_status } # alias
sub status        { shift->current_status } # legacy

sub start {
    my $self = shift;
    my $wait = shift;

    my $s    = $self->current_status;
    croak "Can't start $self: run state=$s" unless $s eq 'stopped';
    my ($i) = $self->aws->start_instances($self) or return;
    if ($wait) {
	while ($i->current_status eq 'pending') {
	    sleep 5;
	}
	$self->refresh;
    }
    return $i;
}

sub stop {
    my $self = shift;
    my $wait = shift;

    my $s    = $self->current_status;
    croak "Can't stop $self: run state=$s" unless $s eq 'running';

    my ($i) = $self->aws->stop_instances($self);
    if ($wait) {
	while ($i->current_status ne 'stopped') {
	    sleep 5;
	}
	$self->refresh;
    }
    return $i;
}

sub terminate {
    my $self = shift;
    my $wait = shift;

    my $s    = $self->current_status;
    croak "Can't terminate $self: run state=$s"
	unless $s eq 'running' or $s eq 'stopped';

    my $i = $self->aws->terminate_instances($self) or return;
    if ($wait) {
	while ($i->current_status ne 'terminated') {
	    sleep 5;
	}
	$self->refresh;
    }
    return $i;
}

sub reboot {
    my $self = shift;

    my $s    = $self->current_status;
    croak "Can't reboot $self: run state=$s"unless $s eq 'running';
    return $self->aws->reboot_instances($self);
}

sub upTime {
    my $self = shift;
    my $start = $self->launchTime;
    VM::EC2::Dispatch::load_module('Date::Parse');
    my $sec = Date::Parse::str2time($start);
    return time()-$sec;
}

sub up_time { shift->upTime }

sub associate_address {
    my $self = shift;
    my $addr = shift or croak "Usage: \$instance->associate_address(\$elastic_address)";
    my $r = $self->aws->associate_address($addr => $self->instanceId);
    return $r;
}

sub disassociate_address {
    my $self = shift;
    my $addr = $self->aws->describe_addresses(-filter=>{'instance-id'=>$self->instanceId});
    $addr or croak "Instance $self is not currently associated with an elastic IP address";
    my $r = $self->aws->disassociate_address($addr);
    return $r;
}

sub refresh {
    my $self = shift;
    my $i   = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_instances_sync(-instance_id=>$self->instanceId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

sub console_output {
    my $self = shift;
    VM::EC2::Dispatch::load_module('VM::EC2::REST::general');
    my $output = $self->aws->get_console_output_sync(-instance_id=>$self->instanceId);
    return $output->output;
}

sub create_image {
    my $self = shift;
    my %args;
    if ($_[0] !~ /^-/) {
	my ($name,$description) = @_;
	$args{-name}         = $name;
	$args{-description}  = $description if defined $description;
    } else {
	%args = @_;
    }
    $args{-name} or croak "Usage: create_image(\$image_name)";
    return $self->aws->create_image(%args,-instance_id=>$self->instanceId);
}

sub attach_volume {
    my $self = shift;
    my %args;
    if (@_==2 && $_[0] !~ /^-/) {
	my ($volume,$device) = @_;
	$args{-volume_id} = $volume;
	$args{-device}    = $device;
    } else {
	%args = @_;
    }
    $args{-volume_id} && $args{-device}
       or croak "usage: \$vol->attach(\$instance_id,\$device)";
    $args{-instance_id} = $self->instanceId;

    my $result = $self->aws->attach_volume(%args);

    if ($VM::EC2::ASYNC) {
	$result->cb(
	    sub {
		my $attach = shift->recv;
		$self->refresh if $attach;
	    });
    } else {
	$self->refresh if $result;
    }

    return $result;
}

sub detach_volume {
    my $self = shift;
    my %args;

    if (@_ == 1 && $_[0] !~ /^-/) {
	my $vol_or_device = shift;
	$self->refresh;
	my @mappings   = $self->blockDeviceMapping;
	my ($mapping)  = grep {$_->deviceName eq $vol_or_device} @mappings;
	if ($mapping) {
	    $args{-volume_id} = $mapping->volumeId;
	    $args{-device}    = $mapping->deviceName;
	} else {
	    $args{-volume_id} = $vol_or_device;
	}
    } else {
	%args = @_;
    }
    $args{-instance_id} = $self->instanceId;
    my $result = $self->aws->detach_volume(%args);
    if ($VM::EC2::ASYNC) {
	$result->cb(
	    sub {
		my $attach = shift->recv;
		$self->refresh if $attach;
	    });
    } else {
	$self->refresh if $result;
    }

    return $result;
}

sub attach_network_interface {
    my $self = shift;
    my %args;
    if (@_==2 && $_[0] !~ /^-/) {
	@args{qw(-network_interface_id -device_index)} = @_; 
    } else {
	%args = @_;
    }
    $args{-network_interface_id} && $args{-device_index}
       or croak "usage: \$instance->attach_network_interface(\$network_interface_id,\$device_index)";

    $args{-instance_id} = $self->instanceId;

    my $result = $self->aws->attach_network_interface(%args);
    if ($VM::EC2::ASYNC) {
	$result->cb(
	    sub {
		my $attach = shift->recv;
		if ($attach) {
		    $self->refresh;
		    eval {$args{-network_interface_id}->refresh};
		}
	    });
    }
    elsif ($result) {
	$self->refresh;
	eval {$args{-network_interface_id}->refresh};
    }

    return $result;
}

sub detach_network_interface {
    my $self = shift;
    my ($nid,$force) = @_;
    $nid or croak "usage: \$instance=>detach_network_interface(\$network_interface_id [,\$force])";
    my ($attachment) = map {$_->attachment} grep { $_->networkInterfaceId eq $nid } $self->network_interfaces;
    $attachment or croak "$self is not attached to $nid";
    my $result = $self->aws->detach_network_interface($attachment,$force);

    if ($VM::EC2::ASYNC) {
	$result->cb(
	    sub {
		my $attach = shift->recv;
		if ($attach) {
		    $self->refresh;
		    eval {$nid->refresh};
		}
	    });
    }
    elsif ($result) {
	$self->refresh;
	eval {$nid->refresh} if $result;
    }

    return $result;
}

sub metadata {
    my $self = shift;
    return $self->aws->instance_metadata;
}

sub productCodes {
    my $self = shift;
    my $codes = $self->SUPER::productCodes or return;
    return map {VM::EC2::ProductCode->new($_)} @{$codes->{item}};
}

sub confirm_product_code {
    my $self = shift;
    my $code = shift;
    return $self->aws->confirm_product_instance($self,$code);
}

1;

