package VM::EC2::Volume::Status::Action;

=head1 NAME

VM::EC2::Volume::Status::Action - Object describing a scheduled volume maintenance event

=head1 SYNOPSIS

 @status_items = $ec2->describe_volume_status();
 for my $i (@status_items) {
    for my $event ($i->events) {
       print $i->volume_id,': ',
             $event->code,' ',
             $event->type, ' ',
             $event->description,"\n";
    }
 }

=head1 DESCRIPTION

This objects reflects the actions you may have to take in response to
a volume event, as described at:

http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumeStatus.html

=head1 METHODS

 code            -- The code identifying the action.

 eventType       -- The ID of the action.

 description     -- A description of the action.

 type            -- Alias for eventType
 
 id              -- Alias for eventId

When used in a string context, this object interpolates as a string
using the action code.

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
    return qw(code eventType eventId description);
}

sub type {shift->eventType}
sub id   {shift->eventId}
sub short_name {
    my $self = shift;
    return $self->code;
}

1;

