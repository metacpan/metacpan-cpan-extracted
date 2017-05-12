package VM::EC2::REST::ebs;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    AttachVolume      => 'VM::EC2::BlockDevice::Attachment',
    CopySnapshot      => sub { shift->{snapshotId} },
    CreateSnapshot    => 'VM::EC2::Snapshot',
    CreateVolume      => 'VM::EC2::Volume',
    DeleteSnapshot    => 'boolean',
    DeleteVolume      => 'boolean',
    DescribeAvailabilityZones  => 'fetch_items,availabilityZoneInfo,VM::EC2::AvailabilityZone',
    DescribeImages    => 'fetch_items,imagesSet,VM::EC2::Image',
    DescribeInstanceStatus => 'fetch_items_iterator,instanceStatusSet,VM::EC2::Instance::StatusItem,instance_status',
    DescribeRegions   => 'fetch_items,regionInfo,VM::EC2::Region',
    DescribeSecurityGroups   => 'fetch_items,securityGroupInfo,VM::EC2::SecurityGroup',
    DescribeSnapshots => 'fetch_items,snapshotSet,VM::EC2::Snapshot',
    DescribeVolumeStatus => 'fetch_items_iterator,volumeStatusSet,VM::EC2::Volume::StatusItem,volume_status',
    DescribeVolumes   => 'fetch_items,volumeSet,VM::EC2::Volume',
    DetachVolume      => 'VM::EC2::BlockDevice::Attachment',
    EnableVolumeIO    => 'boolean',
    ModifySnapshotAttribute => 'boolean',
    ResetSnapshotAttribute  => 'boolean',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME

VM::EC2::REST::ebs - Modules for EC2 EBS volumes

=head1 SYNOPSIS

 use VM::EC2 ':standard';

=head1 METHODS

The methods in this section allow you to query and manipulate EC2 EBS
volumes and snapshots. See L<VM::EC2::Volume> and L<VM::EC2::Snapshot>
for additional functionality provided through the object interface.

Implemented:
 AttachVolume
 CopySnapshot
 CreateSnapshot
 CreateVolume
 DeleteSnapshot
 DeleteVolume
 DescribeSnapshotAttribute
 DescribeSnapshots
 DescribeVolumes
 DescribeVolumeAttribute
 DescribeVolumeStatus
 DetachVolume
 EnableVolumeIO
 ModifySnapshotAttribute
 ModifyVolumeAttribute
 ResetSnapshotAttribute

Unimplemented:
 (none)

=head2 @v = $ec2->describe_volumes(-volume_id=>\@ids,-filter=>\%filters)

=head2 @v = $ec2->describe_volumes(@volume_ids)

Return a series of VM::EC2::Volume objects. Optional arguments:

 -volume_id    The id of the volume to fetch, either a string
               scalar or an arrayref.

 -filter       One or more filters to apply to the search

The -filter argument name can be omitted if there are no other
arguments you wish to pass.

The full list of volume filters can be found at:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumes.html

=cut

sub describe_volumes {
    my $self = shift;
    my %args = $VEP->args(-volume_id,@_);
    my @params = $VEP->format_parms(\%args,
				    {
					list_parm   => 'VolumeId',
					filter_parm => 'Filter'
				    });
    return $self->call('DescribeVolumes',@params);
}

=head2 $v = $ec2->create_volume(-availability_zone=>$zone,-snapshot_id=>$snapshotId,-size=>$size,-volume_type=>$type,-iops=>$iops,-encrypted=>$boolean)

Create a volume in the specified availability zone and return
information about it.

Arguments:

 -availability_zone    -- An availability zone from
                          describe_availability_zones (required)

 -snapshot_id          -- ID of a snapshot to use to build volume from.

 -size                 -- Size of the volume, in GB (between 1 and 1024).

One or both of -snapshot_id or -size are required. For convenience,
you may abbreviate -availability_zone as -zone, and -snapshot_id as
-snapshot.

Optional Arguments:

 -volume_type          -- The volume type.  "standard", "io1", or "gp2"
                          Default is "standard"

 -iops                 -- The number of I/O operations per second (IOPS) that
                          the volume supports.  Range is 100 to 4000.  Required
                          when volume type is io1.  IOPS must be 30-to-1 ratio
                          to size.  ie: 3000 IOPS volume must be at least 100GB.

 -encrypted            -- Specifies whether the volume should be encrypted.
                          Encrypted Amazon EBS volumes may only be attached to
                          instances that support them. Volumes created from
                          encrypted snapshots are also encrypted using the same
                          key as the original volume.
                          See: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html

The returned object is a VM::EC2::Volume object.

=cut

sub create_volume {
    my $self = shift;
    my %args = @_;

    $args{-availability_zone} ||= $args{-zone} or croak "-availability_zone argument is required";
    $args{-snapshot_id}       ||= $args{-snapshot};
    $args{-snapshot_id} || $args{-size} or croak "One or both of -snapshot_id or -size are required";
    if (exists $args{-volume_type} && $args{-volume_type} eq 'io1') {
        $args{-iops} or croak "Argument -iops required when -volume_type is 'io1'";
    }
    elsif ($args{-iops}) {
        croak "Argument -iops cannot be used when volume type is 'standard'";
    }
    my @params = $VEP->format_parms(\%args,
				    {
					single_parm  => [qw(AvailabilityZone SnapshotId Size VolumeType Iops)],
					boolean_parm => 'Encrypted'
				    });
    return $self->call('CreateVolume',@params);
}

=head2 $result = $ec2->delete_volume($volume_id);

Deletes the specified volume. Returns a boolean indicating success of
the delete operation. Note that a volume will remain in the "deleting"
state for some time after this call completes.

=cut

sub delete_volume {
    my $self = shift;
    my %args  = $VEP->args(-volume_id => @_);
    my @param = $VEP->format_parms(\%args,
				   {
				       single_parm => 'VolumeId'
				   });
	
    return $self->call('DeleteVolume',@param);
}

=head2 $attachment = $ec2->attach_volume($volume_id,$instance_id,$device);

=head2 $attachment = $ec2->attach_volume(-volume_id=>$volume_id,-instance_id=>$instance_id,-device=>$device);

Attaches the specified volume to the instance using the indicated
device. All arguments are required:

 -volume_id      -- ID of the volume to attach. The volume must be in
                    "available" state.
 -instance_id    -- ID of the instance to attach to. Both instance and
                    attachment must be in the same availability zone.
 -device         -- How the device is exposed to the instance, e.g.
                    '/dev/sdg'.

The result is a VM::EC2::BlockDevice::Attachment object which
you can monitor by calling current_status():

    my $a = $ec2->attach_volume('vol-12345','i-12345','/dev/sdg');
    while ($a->current_status ne 'attached') {
       sleep 2;
    }
    print "volume is ready to go\n";

or more simply

    my $a = $ec2->attach_volume('vol-12345','i-12345','/dev/sdg');
    $ec2->wait_for_attachments($a);

=cut

sub attach_volume {
    my $self = shift;
    my %args; 
    if ($_[0] !~ /^-/ && @_ == 3) { 
	@args{qw(-volume_id -instance_id -device)} = @_; 
    } else { 
	%args = @_; 
    }
    $args{-volume_id} && $args{-instance_id} && $args{-device} or
	croak "-volume_id, -instance_id and -device arguments must all be specified";
    my @param = $VEP->format_parms(\%args,
				   {
				       single_parm => [qw(VolumeId InstanceId Device)]
				   });
    return $self->call('AttachVolume',@param);
}

=head2 $attachment = $ec2->detach_volume($volume_id)

=head2 $attachment = $ec2->detach_volume(-volume_id=>$volume_id,-instance_id=>$instance_id,
                                         -device=>$device,      -force=>$force);

Detaches the specified volume from an instance.

 -volume_id      -- ID of the volume to detach. (required)
 -instance_id    -- ID of the instance to detach from. (optional)
 -device         -- How the device is exposed to the instance. (optional)
 -force          -- Force detachment, even if previous attempts were
                    unsuccessful. (optional)


The result is a VM::EC2::BlockDevice::Attachment object which
you can monitor by calling current_status():

    my $a = $ec2->detach_volume('vol-12345');
    while ($a->current_status ne 'detached') {
       sleep 2;
    }
    print "volume is ready to go\n";

Or more simply:

    my $a = $ec2->detach_volume('vol-12345');
    $ec2->wait_for_attachments($a);
    print "volume is ready to go\n" if $a->current_status eq 'detached';


=cut

sub detach_volume {
    my $self = shift;
    my %args = $VEP->args(-volume_id => @_);
    my @param = $VEP->format_parms(\%args,
				   {
				       single_parm  => [qw(VolumeId InstanceId Device)],
				       boolean_parm => 'Force'
				   });
    return $self->call('DetachVolume',@param);
}

=head2 $ec2->wait_for_attachments(@attachment)

Wait for all members of the provided list of
VM::EC2::BlockDevice::Attachment objects to reach some terminal state
("attached" or "detached"), and then return a hash reference that maps
each attachment to its final state.

Typical usage:

    my $i = 0;
    my $instance = 'i-12345';
    my @attach;
    foreach (@volume) {
	push @attach,$_->attach($instance,'/dev/sdf'.$i++;
    }
    my $s = $ec2->wait_for_attachments(@attach);
    my @failed = grep($s->{$_} ne 'attached'} @attach;
    warn "did not attach: ",join ', ',@failed;

If no terminal state is reached within a set timeout, then this method
returns undef and sets $ec2->error_str() to a suitable message. The
timeout, which defaults to 10 minutes (600 seconds), can be get or set
with $ec2->wait_for_timeout().

=cut

sub wait_for_attachments {
    my $self = shift;
    $self->wait_for_terminal_state(\@_,
				   ['attached','detached'],
				   $self->wait_for_timeout);
}

=head2 @v = $ec2->describe_volume_status(@volume_ids)

=head2 @v = $ec2->describe_volume_status(\%filters)

=head2 @v = $ec2->describe_volume_status(-volume_id=>\@ids,-filter=>\%filters)

Return a series of VM::EC2::Volume::StatusItem objects. Optional arguments:

 -volume_id    The id of the volume to fetch, either a string
               scalar or an arrayref.

 -filter       One or more filters to apply to the search

 -max_results  Maximum number of items to return (must be more than
                5).

The -filter argument name can be omitted if there are no other
arguments you wish to pass.

The full list of volume filters can be found at:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumeStatus.html

If -max_results is specified, then the call will return at most the
number of volume status items you requested. You may see whether there
are additional results by calling more_volume_status(), and then
retrieve the next set of results with additional call(s) to
describe_volume_status():

 my @results = $ec2->describe_volume_status(-max_results => 10);
 do_something(\@results);
 while ($ec2->more_volume_status) {
    @results = $ec2->describe_volume_status;
    do_something(\@results);
 }

=cut

sub more_volume_status {
    my $self = shift;
    return $self->{volume_status_token} &&
           !$self->{volume_status_stop};
}

sub describe_volume_status {
    my $self = shift;
    my @parms;

    if (!@_ && $self->{volume_status_token} && $self->{volume_status_args}) {
	@parms = (@{$self->{volume_status_args}},NextToken=>$self->{volume_status_token});
    }
    
    else {
	my %args = $VEP->args('-volume_id',@_);
	my @parms = $VEP->format_parms(\%args,
				       {
					   list_parm   => 'VolumeId',
					   filter_parm => 'Filter',
					   single_parm => 'MaxResults'
				       });
	if ($args{-max_results}) {
	    $self->{volume_status_token} = 'xyzzy'; # dummy value
	    $self->{volume_status_args} = \@parms;
	}

    }
    return $self->call('DescribeVolumeStatus',@parms);
}

=head2 $ec2->wait_for_volumes(@volumes)

Wait for all members of the provided list of volumes to reach some
terminal state ("available", "in-use", "deleted" or "error"), and then
return a hash reference that maps each volume ID to its final state.

If no terminal state is reached within a set timeout, then this method
returns undef and sets $ec2->error_str() to a suitable message. The
timeout, which defaults to 10 minutes (600 seconds), can be get or set
with $ec2->wait_for_timeout().

=cut

sub wait_for_volumes {
    my $self = shift;
    $self->wait_for_terminal_state(\@_,
				   ['available','in-use','deleted','error'],
				   $self->wait_for_timeout);
}

=head2 @data = $ec2->describe_volume_attribute($volume_id,$attribute)

This method returns volume attributes.  Only one attribute can be
retrieved at a time. The following is the list of attributes that can be
retrieved:

 autoEnableIO                      -- boolean
 productCodes                      -- list of scalar

These values can be retrieved more conveniently from the
L<VM::EC2::Volume> object returned from describe_volumes():

 $volume->auto_enable_io(1);
 @codes = $volume->product_codes;

=cut

sub describe_volume_attribute {
    my $self = shift;
    @_ == 2 or croak "Usage: describe_volume_attribute(\$instance_id,\$attribute_name)";
    my ($instance_id,$attribute) = @_;
    my @param  = (VolumeId=>$instance_id,Attribute=>$attribute);
    my $result = $self->call('DescribeVolumeAttribute',@param);
    return $result && $result->attribute($attribute);
}

sub modify_volume_attribute {
    my $self = shift;
    my $volume_id = shift or croak "Usage: modify_volume_attribute(\$volumeId,%param)";
    my %args   = @_;
    my @param  = (VolumeId=>$volume_id);
    push @param,('AutoEnableIO.Value'=>$args{-auto_enable_io} ? 'true':'false');
    return $self->call('ModifyVolumeAttribute',@param);
}

=head2 $boolean = $ec2->enable_volume_io($volume_id)

=head2 $boolean = $ec2->enable_volume_io(-volume_id=>$volume_id)

Given the ID of a volume whose I/O has been disabled (e.g. due to
hardware degradation), this method will reenable the I/O and return
true if successful.

=cut

sub enable_volume_io {
    my $self = shift;
    my %args = $self->args('-volume_id',@_);
    $args{-volume_id} or croak "Usage: enable_volume_io(\$volume_id)";
    my @param = $self->single_parm('VolumeId',\%args);
    return $self->call('EnableVolumeIO',@param);
}

=head2 @snaps = $ec2->describe_snapshots(@snapshot_ids)

=head2 @snaps = $ec2->describe_snapshots(-snapshot_id=>\@ids,%other_args)

Returns a series of VM::EC2::Snapshot objects. All arguments
are optional:

 -snapshot_id     ID of the snapshot

 -owner           Filter by owner ID

 -restorable_by   Filter by IDs of a user who is allowed to restore
                   the snapshot

 -filter          Tags and other filters

The -filter argument name can be omitted if there are no other
arguments you wish to pass.

The full list of applicable filters can be found at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html

=cut

sub describe_snapshots {
    my $self = shift;
    my %args = $VEP->args('-snapshot_id',@_);

    my @params = $VEP->format_parms(\%args,
				    {
					list_parm   => [qw(SnapshotId Owner RestorableBy)],
					filter_parm => 'Filter'
				    });
    return $self->call('DescribeSnapshots',@params);
}

=head2 @data = $ec2->describe_snapshot_attribute($snapshot_id,$attribute)

This method returns snapshot attributes. The first argument is the
snapshot ID, and the second is the name of the attribute to
fetch. Currently Amazon defines two attributes:

 createVolumePermission   -- return a list of user Ids who are
                             allowed to create volumes from this snapshot.
 productCodes             -- product codes for this snapshot

The result is a raw hash of attribute values. Please see
L<VM::EC2::Snapshot> for a more convenient way of accessing and
modifying snapshot attributes.

=cut

sub describe_snapshot_attribute {
    my $self = shift;
    @_ == 2 or croak "Usage: describe_snapshot_attribute(\$instance_id,\$attribute_name)";
    my ($snapshot_id,$attribute) = @_;
    my @param  = (SnapshotId=>$snapshot_id,Attribute=>$attribute);
    my $result = $self->call('DescribeSnapshotAttribute',@param);
    return $result && $result->attribute($attribute);
}

=head2 $boolean = $ec2->modify_snapshot_attribute($snapshot_id,-$argument=>$value)

This method changes snapshot attributes. The first argument is the
snapshot ID, and this is followed by an attribute modification command
and the value to change it to.

Currently the only attribute that can be changed is the
createVolumeAttribute. This is done through the following arguments

 -createvol_add_user         -- scalar or arrayref of UserIds to grant create volume permissions to
 -createvol_add_group        -- scalar or arrayref of Groups to remove create volume permissions from
                               (only currently valid value is "all")
 -createvol_remove_user      -- scalar or arrayref of UserIds to remove from create volume permissions
 -createvol_remove_group     -- scalar or arrayref of Groups to remove from create volume permissions

You can abbreviate these to -add_user, -add_group, -remove_user, -remove_group, etc.

See L<VM::EC2::Snapshot> for more convenient methods for interrogating
and modifying the create volume permissions.

=cut

sub modify_snapshot_attribute {
    my $self = shift;
    my $snapshot_id = shift or croak "Usage: modify_snapshot_attribute(\$snapshotId,%param)";
    my %args   = @_;

    # shortcuts
    foreach (qw(add_user remove_user add_group remove_group)) {
	$args{"-createvol_$_"} ||= $args{"-$_"};
    }

    my @param  = (SnapshotId=>$snapshot_id);
    push @param,$self->create_volume_perm_parm('Add','UserId',   $args{-createvol_add_user});
    push @param,$self->create_volume_perm_parm('Remove','UserId',$args{-createvol_remove_user});
    push @param,$self->create_volume_perm_parm('Add','Group',    $args{-createvol_add_group});
    push @param,$self->create_volume_perm_parm('Remove','Group', $args{-createvol_remove_group});
    return $self->call('ModifySnapshotAttribute',@param);
}

=head2 $boolean = $ec2->reset_snapshot_attribute($snapshot_id,$attribute)

This method resets an attribute of the given snapshot to its default
value. The only valid attribute at this time is
"createVolumePermission."

=cut

sub reset_snapshot_attribute {
    my $self = shift;
    @_      == 2 or 
	croak "Usage: reset_snapshot_attribute(\$snapshotId,\$attribute_name)";
    my ($snapshot_id,$attribute) = @_;
    my %valid = map {$_=>1} qw(createVolumePermission);
    $valid{$attribute} or croak "attribute to reset must be 'createVolumePermission'";
    return $self->call('ResetSnapshotAttribute',
		       SnapshotId => $snapshot_id,
		       Attribute  => $attribute);
}


=head2 $snapshot = $ec2->create_snapshot($volume_id)

=head2 $snapshot = $ec2->create_snapshot(-volume_id=>$vol,-description=>$desc)

Snapshot the EBS volume and store it to S3 storage. To ensure a
consistent snapshot, the volume should be unmounted prior to
initiating this operation.

Arguments:

 -volume_id    -- ID of the volume to snapshot (required)

 -description  -- A description to add to the snapshot (optional)

The return value is a VM::EC2::Snapshot object that can be queried
through its current_status() interface to follow the progress of the
snapshot operation.

Another way to accomplish the same thing is through the
VM::EC2::Volume interface:

  my $volume = $ec2->describe_volumes(-filter=>{'tag:Name'=>'AccountingData'});
  $s = $volume->create_snapshot("Backed up at ".localtime);
  while ($s->current_status eq 'pending') {
     print "Progress: ",$s->progress,"% done\n";
  }
  print "Snapshot status: ",$s->current_status,"\n";

=cut

sub create_snapshot {
    my $self = shift;
    my %args = $VEP->args('-volume_id',@_);
    my @params  = $VEP->format_parms(\%args,
				    {
					single_parm => ['VolumeId','Description']
				    });
    return $self->call('CreateSnapshot',@params);
}

=head2 $boolean = $ec2->delete_snapshot($snapshot_id) 

Delete the indicated snapshot and return true if the request was
successful.

=cut

sub delete_snapshot {
    my $self = shift;
    my %args = $VEP->args('-snapshot_id',@_);
    my @params   = $VEP->format_parms(\%args,
				     {
					 single_parm => 'SnapshotId'
				     });
    return $self->call('DeleteSnapshot',@params);
}

=head2 $snapshot = $ec2->copy_snapshot(-source_region=>$region,-source_snapshot_id=>$id,-description=>$desc)

=head2 $snapshot = $ec2->copy_snapshot(-region=>$region,-snapshot_id=>$id,-description=>$desc)

Copies an existing snapshot within the same region or from one region to another.

Required arguments:

 -source_region       -- The region the existing snapshot to copy resides in
 -source_snapshot_id  -- The snapshot ID of the snapshot to copy

 -region              -- Alias for -source_region
 -snapshot_id         -- Alias for -source_snapshot_id

Currently, the DestinationRegion and PresignedUrl API arguments are not
supported.  Therefore, copying encrypted snapshots between regions is
not yet possible.

Optional arguments:

 -description         -- A description of the new snapshot

The return value is a VM::EC2::Snapshot object that can be queried
through its current_status() interface to follow the progress of the
snapshot operation.

=cut

sub copy_snapshot {
    my $self = shift;
    my %args = @_;
    $args{-description} ||= $args{-desc};
    $args{-source_region} ||= $args{-region};
    $args{-source_snapshot_id} ||= $args{-snapshot_id};
    $args{-source_region} or croak "copy_snapshot(): -source_region argument required";
    $args{-source_snapshot_id} or croak "copy_snapshot(): -source_snapshot_id argument required";
    my @params  = $VEP->format_parms(\%args,
				     {
					 single_parm => [qw(SourceRegion SourceSnapshotId Description)]
				     });
    my $snap_id = $self->call('CopySnapshot',@params) or return;
    return eval {
            my $snapshot;
            local $SIG{ALRM} = sub {die "timeout"};
            alarm(60);
            until ($snapshot = $self->describe_snapshots($snap_id)) { sleep 1 }
            alarm(0);
            $snapshot;
    };
}

=head2 $ec2->wait_for_snapshots(@snapshots)

Wait for all members of the provided list of snapshots to reach some
terminal state ("completed", "error"), and then return a hash
reference that maps each snapshot ID to its final state.

This method may potentially wait forever. It has no set timeout. Wrap
it in an eval{} and set alarm() if you wish to timeout.

=cut

sub wait_for_snapshots {
    my $self = shift;
    $self->wait_for_terminal_state(\@_,
				   ['completed','error'],
				   0);  # no timeout on snapshots -- they may take days
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
