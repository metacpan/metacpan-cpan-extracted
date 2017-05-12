package VM::EC2::BlockDevice;

=head1 NAME

VM::EC2::BlockDevice - Object describing how to construct an EC2 block device when launching an image

=head1 SYNOPSIS

  use VM::EC2;

  $ec2        = VM::EC2->new(...);
  $image      = $ec2->describe_images(-image_id=>'ami-123456');
  my @devices = $image->blockDeviceMapping;
  for my $d (@devices) {
    my $virtual_device = $d->deviceName;
    my $snapshot_id    = $d->snapshotId;
    my $volume_size    = $d->volumeSize;
    my $delete         = $d->deleteOnTermination;
  }

=head1 DESCRIPTION

This object represents an Amazon block device associated with an AMI.
The information in it is used to create a new volume when the AMI is launched.
The object is returned by VM::EC2->describe_images().

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 deviceName  -- name of the device, such as /dev/sda1
 virtualName -- virtual device name, such as "ephemeral0"
 noDevice    -- true if no device associated
 ebs         -- parameters used to automatically set up Amazon EBS
                volumes when an instance is booted. This returns
                a VM::EC2::BlockDevice::EBS object.

For your convenience, a number of the ebs() object's methods are
passed through:

 snapshotId  -- ID of the snapshot used to create this EBS when an
                instance is launched from this image.
 volumeSize  -- Size of the EBS volume (in gigs).
 deleteOnTermination -- Whether this EBS will be deleted when the
                instance terminates.
 volumeType  -- The volume type, one of "standard" or "io1"
 iops        -- The number of I/O operations per second that the volume
                supports, an integer between 100 and 4000. Only valid for
                volumes of type "io1".

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as:

 deviceName=snapshotId:volumeSize:deleteOnTermination:volumeType:iops

The :iops portion is only valid when the volumeType is "io1".

e.g.

 /dev/sdg=snap-12345:20:true:standard

This happens to be the same syntax used to specify block device
mappings in run_instances(). See L<VM::EC2>.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::BlockDevice::Attachment>
L<VM::EC2::BlockDevice::EBS>
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
use VM::EC2::BlockDevice::EBS;

use overload '""' => sub {shift()->as_string},
    fallback      => 1;

sub valid_fields {
    my $self  = shift;
    return qw(deviceName virtualName ebs);
}

sub noDevice {
    my $self = shift;
    return exists $self->payload->{noDevice};
}

sub ebs {
    my $self = shift;
    my $ebs = $self->SUPER::ebs;
    return unless $ebs;  # some of these devices are ephemeral
    return $self->{ebs} ||= VM::EC2::BlockDevice::EBS->new($ebs,$self->aws);
}

sub snapshotId { shift->ebs->snapshotId }
sub volumeSize { shift->ebs->volumeSize }
sub deleteOnTermination { shift->ebs->deleteOnTermination }
sub volumeType  { shift->ebs->volumeType }
sub iops        { shift->ebs->iops       }

sub as_string {
    my $self  = shift;
    my $vname = $self->virtualName;
    return $self->deviceName.'='.$vname if $vname && $vname =~ /^ephemeral/;
    my $dot   = $self->deleteOnTermination ? 'true' : 'false';
    my $vtype = $self->volumeType;
    my @type_iops = $vtype eq 'io1' ? ($vtype,$self->iops) : $vtype;
    return $self->deviceName.'='.
	join ':',$self->snapshotId,$self->volumeSize,$dot,@type_iops;
}

1;

