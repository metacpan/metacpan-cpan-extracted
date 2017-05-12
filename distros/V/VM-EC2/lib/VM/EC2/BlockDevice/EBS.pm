package VM::EC2::BlockDevice::EBS;

=head1 NAME

VM::EC2::BlockDevice::EBS - Object describing how to initialize an Amazon EBS volume from an image

=head1 SYNOPSIS

  use VM::EC2;

  $image      = $ec2->describe_images(-image_id=>'ami-123456');
  my @devices = $image->blockDeviceMapping;
  for my $d (@devices) {
    my $ebs = $d->ebs;
    my $snapshot_id    = $ebs->snapshotId;
    my $size           = $ebs->volumeSize;
    my $delete         = $ebs->deleteOnTermination;
  }

=head1 DESCRIPTION

This object is used to describe the parameters used to create an
Amazon EBS volume when running an image. Generally you will not call
this directly, as all its methods are passed through by the
VM::EC2::BlockDevice object returned from the
blockDeviceMapping() call.

See L<VM::EC2::BlockDevice> for a simpler way to get the
information needed.

It is easy to confuse this with
VM::EC2::BlockDevice::Mapping::EBS, which describes the
attachment of an existing EBS volume to an instance. This class is
instead used to store the parameters that will be used to generate a
new EBS volume when an image is launched.

=head1 METHODS

The following object methods are supported:
 
 snapshotId  -- ID of the snapshot used to create this EBS when an
                instance is launched from this image.
 volumeSize  -- Size of the EBS volume (in gigs).
 deleteOnTermination -- Whether this EBS will be deleted when the
                instance terminates. Note that this will return
                perl 0/1 values rather than the strings "false"/"true"
 volumeType  -- The volume type, one of "standard" or "io1"
 iops        -- The number of I/O operations per second that the volume
                supports, an integer between 100 and 2000. Only valid for
                volumes of type "io1".

=head1 STRING OVERLOADING

NONE.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Snapshot>
L<VM::EC2::BlockDevice>

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
    return qw(snapshotId volumeSize deleteOnTermination volumeType iops);
}

sub deleteOnTermination {
    my $self = shift;
    my $dot  = $self->SUPER::deleteOnTermination;
    return $dot eq 'true';
}

1;
