package VM::EC2::Instance::Status::Event;

=head1 NAME

VM::EC2::Instance::Status::Event - Object describing a scheduled instance maintenance event

=head1 SYNOPSIS

 @status_items = $ec2->describe_instance_status();
 for my $i (@status_items) {
    for my $event ($i->events) {
       print $i->instance_id,': ',
             $event->code,' ',
             $event->description, ' ',
             $event->notBefore, ' ',
             $event->notAfter,"\n";
    }
 }

=head1 DESCRIPTION

This objects describes a scheduled maintenance event on an instance,
and is returned by calling the events() method of one of the status
item objects returned by $ec2->describe_instance_status().

NOTE: There is an inconsistency in the AWS documentation for this data
type. The events field is documented as being a list, but the examples
shown show a single object. At release time, I was unable to verify
which is correct and have written the code such that it will detect a
single value in the response object and return this as a single-element
list.

=head1 METHODS

 code()        -- The code for this event, one of "instance-reboot", 
                    "system-reboot", "instance-retirement"

 description() -- A description of the event.

 notBefore()   -- The earliest scheduled start time for the event.

 notAfter()    -- The latest scheduled end time for the event.

When used in a string context, this object interpolates as a string in
the form:

 system-reboot [2011-12-05T13:00:00+0000 - 2011-12-06T13:00:00+000]

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::Instance::State>
L<VM::EC2::Instance::Status>
L<VM::EC2::Instance::StatusItem>
L<VM::EC2::Instance::Status::Details>
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
    return qw(code description notBefore notAfter);
}

sub short_name {
    my $self = shift;
    return $self->code . '['.$self->notBefore.' - '.$self->notAfter.']';;
}

1;

