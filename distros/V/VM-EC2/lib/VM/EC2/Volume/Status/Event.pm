package VM::EC2::Volume::Status::Event;

=head1 NAME

VM::EC2::Volume::Status::Event - Object describing a scheduled volume maintenance event

=head1 SYNOPSIS

 @status_items = $ec2->describe_volume_status();
 for my $i (@status_items) {
    for my $event ($i->events) {
       print $i->volume_id,': ',
             $event->type,' ',
             $event->description, ' ',
             $event->notBefore, ' ',
             $event->notAfter,"\n";
    }
 }

=head1 DESCRIPTION

This objects describes a scheduled maintenance event on an volume,
and is returned by calling the events() method of one of the status
item objects returned by $ec2->describe_volume_status().

NOTE: There is an inconsistency in the AWS documentation for this data
type. The events field is documented as being a list, but the examples
shown show a single object. At release time, I was unable to verify
which is correct and have written the code such that it will detect a
single value in the response object and return this as a single-element
list.

=head1 METHODS

 eventType     -- The type of event

 eventId       -- The ID of the event

 description   -- A description of the event.

 notBefore     -- The earliest scheduled start time for the event.

 notAfter      -- The latest scheduled end time for the event.

 type          -- Alias for eventType
 
 id            -- Alias for eventId

When used in a string context, this object interpolates as a string
using the eventType.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Volume>
L<VM::EC2::Volume::Status>
L<VM::EC2::Volume::StatusItem>
L<VM::EC2::Volume::Status::Details>
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

use strict;

sub valid_fields {
    my $self = shift;
    return qw(eventType eventId description notBefore notAfter);
}

sub type {shift->eventType}
sub id   {shift->eventId}
sub short_name {
    my $self = shift;
    return $self->eventType;
}

1;

