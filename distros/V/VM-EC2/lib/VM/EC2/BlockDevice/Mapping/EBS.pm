package VM::EC2::BlockDevice::Mapping::EBS;

=head1 NAME

VM::EC2::BlockDevice::Mapping::EBS - Object describing an EBS volume that has been mapped onto an Amazon EC2 instance

=head1 SYNOPSIS

  use VM::EC2;

  my $instance  = $ec2->describe_instances(-instance_id=>'i-123456');
  my @devices   = $instance->blockDeviceMapping;
  for my $d (@devices) {
    my $ebs = $d->ebs;
    $volume_id = $ebs->volumeId;
    $status    = $ebs->status;
    $atime     = $ebs->attachmentTime;
    $delete    = $ebs->delete;
    $volume    = $ebs->volume;
  }

=head1 DESCRIPTION

This object is used to describe an Amazon EBS volume that is mapped
onto an EC2 block device. It is returned by
VM::EC2->describe_instances().

It is easy to confuse this with VM::EC2::BlockDevice::EBS, which
describes the parameters needed to create the EBS volume when an image
is launched. This class is instead used to describe an active mapping
between an instance's block device and the underlying EBS volume.

Because all the methods in this class are passed through to
VM::EC2::BlockDeviceMapping, it is somewhat simpler to call
them directly on the BlockDeviceMapping object:

  my $instance  = $ec2->describe_instances(-instance_id=>'i-123456');
  my @devices   = $instance->blockDeviceMapping;
  for my $d (@devices) {
    $volume_id = $d->volumeId;
    $status    = $d->status;
    $atime     = $d->attachmentTime;
    $delete    = $d->delete;
    $volume    = $d->volume;
  }

=head1 METHODS

The following object methods are supported:
 
 volumeId         -- ID of the volume.
 status           -- One of "attaching", "attached", "detaching", "detached"
 attachTime       -- Time this volume was attached
 deleteOnTermination -- Whether the volume will be deleted when its attached
                      instance is deleted. Note that this returns the perl
                      0/1 booleans rather than "false"/"true" strings.

In addition, the following convenience method is supported:

=head2 $vol = $ebs->volume

This returns the VM::EC2::Volume object that corresponds to this
EBS. The volume will provide additional information, such as
availabilit zone.

=head1 STRING OVERLOADING

NONE

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Snapshot>
L<VM::EC2::BlockDevice>
L<VM::EC2::BlockDevice::Attachment>

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

sub valid_fields {
    my $self = shift;
    return qw(volumeId status attachTime deleteOnTermination);
}

sub volume {
    my $self = shift;
    return $self->{volume} if exists $self->{volume};
    my @vols = $self->aws->describe_volumes(-volume_id=>$self->volumeId) or return;
    @vols == 1 or die "describe_volumes(-volume_id=>",$self->volumeId,") returned more than one volume";
    return $self->{volume} = $vols[0];
}

sub deleteOnTermination {
    my $self = shift;
    my $dot  = $self->SUPER::deleteOnTermination;
    return $dot eq 'true';
}

1;
