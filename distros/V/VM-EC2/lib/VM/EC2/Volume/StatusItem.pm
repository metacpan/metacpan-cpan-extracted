package VM::EC2::Volume::StatusItem;

=head1 NAME

VM::EC2::Volume::StatusItem - Object describing a volume status event

=head1 SYNOPSIS

 @status_items = $ec2->describe_volume_status();
 for my $i (@status_items) {
    print $i->volume_id,': ',$i->status,"\n";
    if (my $e = $i->events) {
       print $i->volume_id,' event = ',$e;
    }
 }

=head1 DESCRIPTION

This object represents an volume status returned by
$ec2->describe_volume_status().

=head1 METHODS

These object methods are supported:

 volumeId             -- The ID of the affected volume.
 volume               -- The VM::EC2::Volume object corresponding to the volume_id.

 availability_zone    -- The availability zone of this volume.

 volumeStatus         -- A VM::EC2::Volume::Status object indicating the status of the volume.
 status               -- Shorter version of the above.

 actionsSet           -- The list of actions that you might wish to take
                            in response to this status, represented as
                            VM::EC2::Volume::Status::Action objects.
 actions              -- Shorter version of the above.

 eventsSet            -- A list of VM::EC2::Volume::Status::Event objects
                           which provide information about the nature and time
                           of the event.
 events               -- Shorter version of the above.


NOTE: There are a number of inconsistencies in the AWS documentation
for this data type. The event and action fields are described as being
named eventSet and actionSet, but the XML example and practical
experience show the fields being named eventsSet and actionsSet. The
volumeStatus is documented as being a list, but practice shows that it
is a single value only.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::Tag>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::Volume::Status;
use VM::EC2::Volume::Status::Event;
use VM::EC2::Volume::Status::Action;

sub valid_fields {
    my $self = shift;
    return qw(volumeId availabilityZone volumeStatus eventsSet actionsSet);
}

sub volume {
    my $self = shift;
    return $self->ec2->describe_volumes($self->volumeId);
}

sub volumeStatus {
    my $self = shift;
    my $s    = $self->SUPER::volumeStatus or return;
    return VM::EC2::Volume::Status->new($s,$self->ec2);
}

sub status { shift->volumeStatus }

sub eventsSet {
    my $self = shift;
    my $e    = $self->SUPER::eventsSet or return;
    return map {VM::EC2::Volume::Status::Event->new($_,$self->ec2)} @{$e->{item}};
}

sub events { shift->eventsSet }

sub actionsSet {
    my $self = shift;
    my $e    = $self->SUPER::actionsSet or return;
    return map {VM::EC2::Volume::Status::Action->new($_,$self->ec2)} @{$e->{item}};
}

sub actions { shift->actionsSet }

sub short_name {
    my $self = shift;
    my $volume = $self->volumeId;
    my $status = ($self->status)[0];
    return "$volume: $status";
}


1;

