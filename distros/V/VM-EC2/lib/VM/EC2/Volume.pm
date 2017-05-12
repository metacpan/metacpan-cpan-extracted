package VM::EC2::Volume;

=head1 NAME

VM::EC2::Volume - Object describing an Amazon EBS volume

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @vol = $ec2->describe_volumes;
  for my $vol (@vols) {
    $id    = $vol->volumeId;
    $size  = $vol->size;
    $snap  = $vol->snapshotId;
    $zone  = $vol->availabilityZone;
    $status = $vol->status;
    $ctime = $vol->createTime;
    @attachments = $vol->attachments;
    $attachment  = $vol->attachment;
    $origin      = $vol->from_snapshot;
    @snapshots   = $vol->to_snapshots;
  }
  $vols[0]->attach('i-12345','/dev/sdg1');
  $vols[0]->deleteOnTermination('true');
  $vols[0]->detach;
  $vols[0]->create_snapshot('automatic snapshot')

=head1 DESCRIPTION

This object is used to describe an Amazon EBS volume. It is returned
by VM::EC2->describe_volumes().

=head1 METHODS

The following object methods are supported:
 
 volumeId         -- ID of this volume.
 size             -- Size of this volume (in GB).
 snapshotId       -- ID of snapshot this volume was created from.
 availabilityZone -- Availability zone in which this volume resides.
 status           -- Volume state, one of "creating", "available",
                     "in-use", "deleting", "deleted", "error"
 createTime       -- Timestamp for when volume was created.
 volumeType       -- The volume type, one of "standard", "io1", or "gp2"
 iops             -- The number of I/O operations per second that the volume
                     supports, an integer between 100 and 4000. Only valid for
                     volumes of type "io1".
 encrypted        -- True if volume is encrypted.
 tags             -- Hashref containing tags associated with this group.
                     See L<VM::EC2::Generic>.

In addition, this class provides several convenience functions:

=head2 $attachment  = $vol->attachment

=head2 @attachments = $vol->attachments

The attachment() method returns a
VM::EC2::BlockDevice::Attachment object describing the
attachment of this volume to an instance. If the volume is unused,
then this returns undef.

The attachments() method is similar, except that it returns a list of
the attachments.  Currently an EBS volume can only be attached to one
instance at a time, but the Amazon call syntax supports multiple
attachments and this method is provided for future compatibility.

=head2 $attachment = $vol->attach($instance,$device)

=head2 $attachment = $vol->attach(-instance_id=>$instance,-device=>$device)

Attach this volume to an instance using virtual device $device. Both
arguments are required. The result is a
VM::EC2::BlockDevice::Attachment object which you can monitor by
calling current_status():

    my $a = $volume->attach('i-12345','/dev/sdg');
    while ($a->current_status ne 'attached') {
       sleep 2;
    }
    print "volume is ready to go\n";

=head2 $attachment = $volume->detach()

=head2 $attachment = $volume->detach(-instance_id=>$instance_id,
                                  -device=>$device,
                                  -force=>$force);

Detaches this volume. With no arguments, will detach the volume from
whatever instance it is currently attached to. Provide -instance_id
and/or -device as a check that you are detaching the volume from the
expected instance and device.

Optional arguments:

 -instance_id    -- ID of the instance to detach from.
 -device         -- How the device is exposed to the instance.
 -force          -- Force detachment, even if previous attempts were
                    unsuccessful.

The result is a VM::EC2::BlockDevice::Attachment object which
you can monitor by calling current_status():

    my $a = $volume->detach;
    while ($a->current_status ne 'detached') {
       sleep 2;
    }
    print "volume is ready to go\n";

=head2 $boolean = $vol->deleteOnTermination([$boolean])

Get or set the deleteOnTermination flag for attached volumes. If the volume 
is unattached, then this causes a fatal error. Called with no arguments, this
method returns the current state of the deleteOnTermination flag for the
volume's attachment. Called with a true/false argument, the method sets the
flag by calling modify_instance_attributes() on the corresponding instance
and returns true if successful.

=head2 $snap = $vol->from_snapshot

Returns the VM::EC2::Snapshot object that this volume was
originally derived from. It will return undef if the resource no
longer exists, or if the volume was created from scratch.

=head2 @snap = $vol->to_snapshots

If this volume has been used to create one or more snapshots, this
method will return them as a list of VM::EC2::Snapshot objects.

=head2 $snapshot = $vol->create_snapshot('Description')

Create a snapshot of the volume and return a VM::EC2::Snapshot
object. To ensure a consistent snapshot, you should unmount the volume
before snapshotting it. The optional argument allows you to add a description to the snapshot.

Here is an example:

  $s = $volume->create_snapshot("Backed up at ".localtime);
  while ($s->current_status eq 'pending') {
     print "Progress: ",$s->progress,"% done\n";
  }
  print "Snapshot status: ",$s->current_status,"\n";

=head2 $status = $vol->current_status

This returns the up-to-date status of the volume. It works by calling
refresh() and then returning status().

=head2 $boolean = $vol->auto_enable_io([$new_boolean])

Get or set the auto-enable IO flag.

=head2 $boolean = $vol->enable_volume_io()

Enable volume I/O after it has been disabled by an Amazon health
check. If successful, the call will return true.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
volumeId.

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
use VM::EC2::BlockDevice::Attachment;
use VM::EC2::ProductCode;
use Carp 'croak';

sub valid_fields {
    my $self = shift;
    return qw(volumeId size snapshotId availabilityZone status 
              createTime attachmentSet volumeType iops encrypted tagSet);
}

sub primary_id {shift->volumeId}

sub attachment {
    my $self = shift;
    my $attachments = $self->attachmentSet or return;
    my $id = $attachments->{item}[0]       or return;
    return VM::EC2::BlockDevice::Attachment->new($id,$self->aws)
}

sub attachments {
    my $self = shift;
    my $attachments = $self->attachmentSet         or return;
    my $items       = $self->attachmentSet->{item} or return;
    my @a = map {VM::EC2::BlockDevice::Attachment->new($_,$self->aws)} @$items;
    return @a;
}

sub deleteOnTermination {
    my $self = shift;
    $self->refresh;
    my $attachment = $self->attachment or croak "$self is not attached";
    return $attachment->deleteOnTermination(@_);
}

sub from_snapshot {
    my $self = shift;
    my $sid  = $self->snapshotId or return;
    return $self->aws->describe_snapshots(-filter=>{'snapshot-id' => $sid});
}

sub to_snapshots {
    my $self = shift;
    return $self->aws->describe_snapshots(-filter=>{'volume-id' => $self->volumeId});
}

sub create_snapshot {
    my $self = shift;
    my $description = shift;
    my @param = (-volume_id=>$self->volumeId);
    push @param,(-description=>$description) if defined $description;
    return $self->aws->create_snapshot(@param);
}

sub attach {
    my $self = shift;
    my %args;
    if (@_==2 && $_[0] !~ /^-/) {
	@args{'-instance_id','-device'} = @_;
    } else {
	%args = @_;
    }
    $args{-instance_id} && $args{-device}
       or croak "usage: \$vol->attach(\$instance_id,\$device)";
    $args{-volume_id} = $self->volumeId;
    return $self->aws->attach_volume(%args);
}

sub detach {
    my $self = shift;
    return $self->aws->detach_volume(-volume_id=>$self->volumeId,@_);
}

sub current_status {
    my $self = shift;
    $self->refresh;
    $self->status;
}

sub current_status_async {
    my $self = shift;
    my $to_caller = VM::EC2->condvar;

    my $cv = $self->aws->describe_volumes_async($self->volumeId);

    $cv->cb(sub {
	my $i = shift->recv;
	if ($i) {
	    $to_caller->send($i->status);
	} else {
	    $to_caller->send;
	}
	    });

    return $to_caller;
}


sub refresh {
    my $self = shift;
    local $self->aws->{raise_error} = 1;
    my $v    = $self->aws->describe_volumes($self->volumeId);
    %$self   = %$v if $v;
    return defined $v;
}

sub auto_enable_io {
    my $self = shift;
    return $self->aws->modify_volume_attribute($self,
					       -auto_enable_io => shift) if @_;
    return $self->aws->describe_volume_attribute($self,'autoEnableIO');
}

sub enable_io {
    my $self = shift;
    $self->aws->enable_volume_io($self);
}

sub product_codes {
    my $self = shift;
    my @codes = $self->aws->describe_volume_attribute($self,'productCodes');
    return map {VM::EC2::ProductCode->new($_,$self->aws)} @codes;
}

sub encrypted {
    my $self = shift;
    my $enc = $self->SUPER::encrypted;
    return $enc eq 'true';
}

1;
