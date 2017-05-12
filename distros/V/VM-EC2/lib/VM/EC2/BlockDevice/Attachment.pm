package VM::EC2::BlockDevice::Attachment;

=head1 NAME

VM::EC2::BlockDevice::Attachment - Object describing the attachment of an EBS volume to an instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2         = VM::EC2->new(...);
  $volume      = $ec2->describe_volumes(-volume_id=>'vol-12345');
  $attachment  = $ec2->attachment;

  $volId       = $attachment->volumeId;
  $device      = $attachment->device;
  $instanceId  = $attachment->instanceId;
  $status      = $attachment->status;
  $time        = $attachment->attachTime;
  $delete      = $attachment->deleteOnTermination;
  $attachment->deleteOnTermination(1); # change delete flag

=head1 DESCRIPTION

This object is used to describe the attachment of an Amazon EBS volume
to an instance. It is returned by VM::EC2::Volume->attachment().

=head1 METHODS

The following object methods are supported:
 
 volumeId         -- ID of the volume.
 instanceId       -- ID of the instance
 status           -- Attachment state, one of "attaching", "attached",
                     "detaching", "detached".
 attachTime       -- Timestamp for when volume was attached
 deleteOnTermination -- True if the EBS volume will be deleted when its
                     attached instance terminates. Note that this is a
                     Perl true, and not the string "true".

The deleteOnTermination method is slightly more sophisticated than 
the result from the standard AWS API because it returns the CURRENT
deleteOnTermination flag for the attachment, which might have been
changed by VM::EC2->modify_instance_attributes(). You may also change
the deleteOnTermination state by passing a boolean argument to the
method:

  $attachment->deleteOnTermination(1);

In addition, this class provides several convenience functions:

=head2 $instance  = $attachment->instance

Returns the VM::EC2::Instance corresponding to this attachment.

=head2 $volume  = $attachment->volume

Returns the VM::EC2::Volume object corresponding to this
attachment.

=head2 $device = $attachment->deviceName

Alias for device() to be compatible with VM::EC2::BlockDevice::Mapping call.

=head2 $result = $attachment->deleteOnTermination($boolean)

Change the deleteOnTermination flag on this attachment.

=head2 $status = $attachment->current_status

Refreshes the information in the object and returns status().

=head2 $attachment->refresh

Calls AWS to refresh the attachment information.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate into a
string of the format "volumeId=>instanceId".

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

sub valid_fields {
    my $self = shift;
    return qw(volumeId instanceId device status attachTime deleteOnTermination);
}

sub primary_id {
    my $self = shift;
    return join ('=>',$self->volumeId,$self->instanceId);
}

sub current_status {
    my $self = shift;
    my $v    = $self->aws->describe_volumes($self->volumeId) or return;
    my $a    = $v->attachment or return 'detached';
    return $a->status;
}

sub current_status_async {
    my $self = shift;
    my $to_caller = VM::EC2->condvar;

    my $cv = $self->aws->describe_volumes_async($self->volumeId);

    $cv->cb(sub {
	my $v   = shift->recv;
	my $a   = $v->attachment;
	if ($a) {
	    $to_caller->send($a->status);
	} else {
	    $to_caller->send('detached');
	}
	    
	    });

    return $to_caller;
}


sub refresh {
    my $self = shift;
    my $v    = $self->aws->describe_volumes($self->volumeId);
    my $a    = $v && $v->attachment;
    %$self   = %$a if $a;
    return defined $a;
}

sub deviceName { shift->device }

sub deleteOnTermination {
    my $self = shift;

    if (@_) {
	my $deleteOnTermination = shift;
	$deleteOnTermination  ||= 0;
	my $flag = $self->device.'='.$self->volumeId.":$deleteOnTermination";
	return $self->aws->modify_instance_attribute($self->instanceId,-block_devices=>$flag);
    }

    my $device    = $self->device;
    my $instance  = $self->instance or die $self->aws->error_str;
    my @mapping   = $instance->blockDeviceMapping;
    my ($map)     = grep {$_ eq $device} @mapping;
    $map or die "Didn't find blockDeviceMapping corresponding to this attachment";
    return $map->deleteOnTermination;
}

sub instance {
    my $self = shift;
    return $self->{instance} if exists $self->{instance};
    my @i    = $self->aws->describe_instances(-instance_id => $self->instanceId);
    @i == 1 or die "describe_instances(-instance_id=>",$self->instanceId,") returned more than one volume";
    return $self->{instance} = $i[0];
}

sub volume {
    my $self = shift;
    return $self->{volume} if exists $self->{volume};
    my @i    = $self->aws->describe_volumes(-volume_id => $self->volumeId);
    @i == 1 or die "describe_volumes(-volume_id=>",$self->volumeId,") returned more than one volume";
    return $self->{volume} = $i[0];
}



1;
