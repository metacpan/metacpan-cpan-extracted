package VM::EC2::BlockDevice::Mapping;

=head1 NAME

VM::EC2::BlockDevice::Mapping - Object describing an EC2 block device attached to an instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2        = VM::EC2->new(...);
  $instance   = $ec2->describe_instances(-instance_id=>'i-123456');
  my @devices   = $instance->blockDeviceMapping;
  for my $dev (@devices) {
    $dev       = $dev->deviceName;
    $volume_id = $dev->volumeId;
    $status    = $dev->status;
    $atime     = $dev->attachmentTime;
    $delete    = $dev->deleteOnTermination;
    $volume    = $dev->volume;
  }

=head1 DESCRIPTION

This object represents an Amazon block device associated with an instance;
it is returned by Instance->blockDeviceMapping().

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 deviceName  -- Name of the device, such as /dev/sda1.
 instance    -- Instance object associated with this volume.
 ebs         -- A VM::EC2::BlockDevice::Mapping::EBS object
                describing the characteristics of the attached
                EBS volume

For your convenience, a number of the ebs() object's methods are
passed through:

 volumeId         -- ID of the volume.
 status           -- One of "attaching", "attached", "detaching", "detached"
 attachTime       -- Time this volume was attached
 deleteOnTermination -- Whether the volume will be deleted when its attached
                   instance is deleted. Note that this will return perl true/false
                   vales, rather than the strings "true" "false".

The deleteOnTermination() method can be used to retrieve or modify this flag:

 # get current deleteOnTermination flag
 my $current_flag = $dev->deleteOnTermination;

 # if flag is true, then set it to false
 if ($current_flag) { $dev->deleteOnTermination(0) }

In addition, the following convenience function is provided:

=head2 $volume = $dev->volume

This returns a VM::EC2::Volume object from which more
information about the volume, such as its size, can be derived.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
deviceName.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::BlockDevice::Attachment>
L<VM::EC2::BlockDevice::Mapping::EBS>
L<VM::EC2::Volume>

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
use VM::EC2::BlockDevice::Mapping::EBS;

use overload '""' => sub {shift()->deviceName},
    fallback      => 1;

sub valid_fields {
    my $self  = shift;
    return qw(deviceName ebs);
}

sub ebs {
    my $self = shift;
    return $self->{ebs} ||= VM::EC2::BlockDevice::Mapping::EBS->new($self->SUPER::ebs,$self->aws);
}

sub instance     {
    my $self = shift;
    my $d = $self->{instance};
    $self->{instance} = shift if @_;
    return $d;
}
sub volumeId     { shift->ebs->volumeId }
sub status       { shift->ebs->status   }
sub attachTime   { shift->ebs->attachTime   }
sub volume       { shift->ebs->volume }

sub deleteOnTermination   { 
    my $self = shift;
    my $ebs  = $self->ebs;
    my $flag = $ebs->deleteOnTermination;
    if (@_) {
	my $deleteOnTermination = shift;
	$deleteOnTermination  ||= 0;
	my $flag = $self->deviceName.'='.$self->volumeId.":$deleteOnTermination";
	return $self->aws->modify_instance_attribute($self->instance,-block_devices=>$flag);
    }
    return $flag;
}

1;

