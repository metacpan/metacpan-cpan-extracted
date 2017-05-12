package VM::EC2::Snapshot;

=head1 NAME

VM::EC2::Snapshot - Object describing an Amazon EBS snapshot

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @snap = $ec2->describe_snapshots;
  for my $snap (@snapshots) {
      $id    = $snap->snapshotId;
      $vol   = $snap->volumeId;
      $state = $snap->status;
      $time  = $snap->startTime;
      $progress = $snap->progress;
      $size  = $snap->volumeSize;
      $description = $snap->description;
      $tags  = $snap->tags;
  }

 # use a snapshot as the root device for a new AMI
 $ami = $snap->register_image(-name         => 'My new image',
                               -kernel_id    => 'aki-407d9529',
                               -architecture => 'i386');

 #create a volume from the snapshot
 $vol = $snap->create_volume(-zone => 'us-east-1a');

=head1 DESCRIPTION

This object is used to describe an Amazon EBS snapshot.

=head1 METHODS

The following object methods are supported:
 
 snapshotId       -- ID of this snapshot
 ownerId          -- Owner of this snapshot
 volumeId         -- ID of the volume snapshot was taken from
 status           -- Snapshot state, one of "pending", "completed" or "error"
 startTime        -- Timestamp for when snapshot was begun.
 progress         -- The progress of the snapshot, in percent.
 volumeSize       -- Size of the volume, in gigabytes.
 description      -- Description of the snapshot
 ownerAlias       -- AWS account alias, such as "self".
 encrypted        -- True if snapshot is encrypted
 tags             -- Hashref containing tags associated with this group.
                     See L<VM::EC2::Generic>.

In addition, this class provides several convenience functions:

=head2 $vol = $snap->from_volume

Returns the VM::EC2::Volume object that this snapshot was originally
derived from. If the original volume no longer exists because it has
been deleted, this will return undef; if -raise_error was passed to
the VM::EC2 object, this will raise an exception.

=head2 @vol = $snap->to_volumes

Returns all VM::EC2::Volume objects that were derived from this
snapshot. If no volumes currently exist that satisfy this criteria,
returns an empty list, but will not raise an error.

=head2 $image = $snap->register_image(%args)

Register a new AMI using this snapshot as the root device. By default,
the root device will be mapped to /dev/sda1 and will delete on
instance termination. You can modify this behavior and add additional
block devices.

Arguments:

 -name                 Name for this image (required)

 -description          Description of this image

 -kernel_id            Kernel for this image (recommended)

 -ramdisk_id           Ramdisk for this image

 -architecture         Architecture ("i386" or "x86_64")

 -root_device_name     Specify the root device based
                       on this snapshot (/dev/sda1).

 -root_size            Size of the root volume (defaults
                       to size of the snapshot).

 -root_delete_on_termination   True value (default) to delete
                       the root volume after the instance
                       terminates. False value to keep the
                       EBS volume available.

 -block_device_mapping Additional block devices you wish to
                       incorporate into the image.

 -block_devices        Same as above.

See L<VM::EC2> for information on the syntax of the
-block_device_mapping argument. If the root device is explicitly
included in the block device mapping argument, then the arguments
specified in -root_size, and -root_delete_on_termination will be
ignored, and the current snapshot will not automatically be used as
the root device.

The return value is a L<VM::EC2::Image>. You can call its
current_status() method to poll its availability:

  $snap = $ec2->describe_snapshots('snap-123456');
  $ami = $snap->register_image(-name          => 'My new image',
                               -kernel_id     => 'aki-407d9529',
                               -architecture  => 'i386',
                               -block_devices => '/dev/sdc=ephemeral0'
  ) or die $ec2->error_str;

  while ($ami->current_status eq 'pending') {
    print "$ami: ",$ami->current_status,"\n"
    sleep 30;  # takes a long time to register some images
  }

  print "$ami is ready to go\n";

=head2 $volume = $snap->create_volume(%args)

Create a new volume from this snapshot. Arguments are:

 -availability_zone    -- An availability zone from
                          describe_availability_zones (required)

 -size                 -- Size of the volume, in GB (between 1 and 1024).

If -size is not provided, then the new volume will have the same size as
the snapshot. 

Optional Arguments:

 -volume_type          -- The volume type.  standard or io1, default is
                          standard

 -iops                 -- The number of I/O operations per second (IOPS) that
                          the volume supports.  Range is 100 to 4000.  Required
                          when volume type is io1.  IOPS must be 30-to-1 ratio
                          to size.  ie: 3000 IOPS volume must be at least 100GB.

On success, the returned value is a L<VM::EC2::Volume> object.

=head2 $status = $snap->current_status

Refreshes the snapshot and returns its current status.

=head2 $boolean = $snapshot->is_public

Return true if the snapshot's createVolume permissions allow the "all"
group to create volumes from the snapshot.

=head2 $boolean = $snapshot->make_public($public)

Modify the createVolumePermission attribute to allow the "all" group
to create volumes from this snapshot. Provide a true value to make the
snapshot public, a false one to make it private.

=head2 @user_ids = $snap->createVolumePermissions()

=head2 @user_ids = $snap->authorized_users

Returns a list of user IDs with createVolume permissions for this
snapshot. The result is a list of L<VM::EC2::Snapshot::CreateVolumePermission>
objects, which interpolate as strings corresponding to either the
user ID, or the group named "all."

The two methods are aliases of each other.

=head2 $boolean = $snap->add_authorized_users($id1,$id2,...)

=head2 $boolean = $snap->remove_authorized_users($id1,$id2,...)

=head2 $boolean = $snap->reset_authorized_users

These methods add and remove user accounts which have createVolume
permissions for the snapshot. The result code indicates whether the
list of user IDs were successfully added or removed. To add the "all"
group, use make_public().

reset_authorized_users() resets the list users authored to create
volumes from this snapshot to empty, effectively granting volume
creation to the owner only.

See also authorized_users().

=head2 $size = $snap->size

Alias to volumeSize, provided for consistency with
VM::EC2::Volume->size.

=head2 $snap->refresh

Refreshes the snapshot from information provided by AWS. Use before
checking progress or other changeable elements.

=head2 $snapshot_copy = $snapshot->copy(-region=>$dest_region, -description=>$desc)

Copies the snapshot to the same or different region.

Required Argument:
 -region        The region to copy the snapshot to

Optional Argument:
 -description   Description of the new snapshot

Returns a VM::EC2::Snapshot object if successful.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
snapshotId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
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
use VM::EC2::Snapshot::CreateVolumePermission;
use VM::EC2::ProductCode;
use Carp 'croak';

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(snapshotId
              volumeId
              status
              startTime
              progress
              ownerId
              volumeSize
              description
              encrypted
              ownerAlias);
}

sub primary_id { shift->snapshotId }

sub size { shift->volumeSize }

sub from_volume {
    my $self = shift;
    my $vid = $self->volumeId or return;
    # may throw an error if volume no longer exists
    return $self->aws->describe_volumes(-volume_id=>$vid);
}

sub to_volumes {
    my $self = shift;
    return $self->aws->describe_volumes(-filter=>{'snapshot-id'=>$self->snapshotId});
}

sub refresh {
    my $self = shift;
    local $self->aws->{raise_error} = 1;
    my $s = $self->aws->describe_snapshots($self);
    %$self  = %$s if $s;
    return defined $s
}

sub register_image {
    my $self = shift;
    my %args = @_;
    $args{-name}               or croak "register_image(): -name argument required";
    $args{-root_device_name}   ||= '/dev/sda1';

    my $block_devices = $args{-block_devices} || $args{-block_device_mapping} || [];
    $block_devices    = [$block_devices] unless ref $block_devices && ref $block_devices eq 'ARRAY';

    # See if the root device is on the block device mapping list.
    # If it is not, then create a /dev/sda1 entry for it from this snapshot.
    my $rd = $args{-root_device_name};
    unless (grep {/$rd=/} @$block_devices) {
	my $root_size   = $args{-root_size}   || '';
	$args{-root_delete_on_termination} = 1 unless defined $args{-root_delete_on_termination};
	my $root_delete = $args{-root_delete_on_termination} ? 'true' : 'false';
	my $snap_id     = $self->snapshotId;
	unshift @$block_devices,"$rd=$snap_id:$root_size:$root_delete"
    }

    $args{-block_device_mapping} = $block_devices;

    # just cleaning up, not really necessary
    delete $args{-root_size};
    delete $args{-root_delete_on_termination};

    return $self->aws->register_image(%args);
}

sub create_volume {
    my $self = shift;
    my @args = @_;
    return $self->ec2->create_volume(@args,-snapshot_id=>$self->snapshotId);
}

sub current_status {
    my $self = shift;
    $self->refresh;
    return $self->status;
}

sub current_status_async {
    my $self = shift;
    my $to_caller = VM::EC2->condvar;

    my $cv = $self->aws->describe_snapshots_async(-snapshot_id=>$self->snapshotId);

    $cv->cb(sub {
	my $i = shift->recv;
	$to_caller->send($i->status)
	    });

    return $to_caller;
}


sub createVolumePermissions {
    my $self = shift;
    my @users = map {VM::EC2::Snapshot::CreateVolumePermission->new($_,$self->aws)}
        $self->aws->describe_snapshot_attribute($self->snapshotId,'createVolumePermission');

    # work around an apparent AWS bug discovered 23 October 2014 in which call returns
    # duplicate user IDs
    my %seenit;
    return grep {!$seenit{$_}++} @users;
}

sub is_public {
    my $self  = shift;
    my @users = $self->createVolumePermissions;
    my $count = grep {$_->group eq 'all'} @users;
    return $count > 0;
}

sub make_public {
    my $self = shift;
    @_ == 1 or croak "Usage: VM::EC2::Snapshot->make_public(\$boolean)";
    my $public = shift;
    my @arg    = $public ? (-add_group=>'all') : (-remove_group=>'all');
    my $result = $self->aws->modify_snapshot_attribute($self->snapshotId,@arg) or return;
    return $result
}

sub authorized_users { shift->createVolumePermissions }

sub add_authorized_users {
    my $self = shift;
    @_ or croak "Usage: VM::EC2::Snapshot->add_authorized_users(\@userIds)";
    return $self->aws->modify_snapshot_attribute($self->snapshotId,-add_user=>\@_);
}

sub remove_authorized_users {
    my $self = shift;
    @_ or croak "Usage: VM::EC2::Snapshot->remove_authorized_users(\@userIds)";
    return $self->aws->modify_snapshot_attribute($self->snapshotId,-remove_user=>\@_);
}

sub reset_authorized_users {
    my $self = shift;
    $self->aws->reset_snapshot_attribute($self->snapshotId,'createVolumePermission');
}


sub product_codes {
    my $self = shift;
    my @codes = $self->aws->describe_snapshot_attribute($self,'productCodes');
    return map {VM::EC2::ProductCode->new($_,$self->aws)} @codes;
}

sub copy {
    my $self = shift;
    my %args = @_;
    my $snap_id = $self->snapshotId;   
    my $desc    = $args{-description} || $args{-desc};
    my $region  = $args{-region} or croak "copy(): -region argument required";
    my $orig_region = $self->aws->region;

    # create a new EC2 object for the destination
    my $dest_aws = $self->aws->clone;
    $dest_aws->region($region);
    my $snapshot = $dest_aws->copy_snapshot(-source_region=>$orig_region, -source_snapshot_id=>$snap_id, -description=>$desc);
    return $snapshot;
}

sub encrypted {
    my $self = shift;
    my $enc = $self->SUPER::encrypted;
    return $enc eq 'true';
}

1;
