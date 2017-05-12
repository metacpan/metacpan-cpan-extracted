package VM::EC2::Volume::Status;

=head1 NAME

VM::EC2::Volume::Status - Object describing an volume/system status check

=head1 SYNOPSIS

 @status_items = $ec2->describe_volume_status();
 for my $i (@status_items) {
   print $i->volume_id,': ',$i->status,"\n";
   if ($i->status ne 'ok') {
      print $i->status->details,"\n";
   }
 }

=head1 DESCRIPTION

This object represents the result of a volume status check operation.

=head1 METHODS

The following methods are supported:

 status()              -- The status, one of "ok", "impaired", "insufficient-data",
                            or "not-applicable"
 details()             -- A list of information about system volume health or
                           application volume health.

In a string context, this object interpolates with the status string.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::State>
L<VM::EC2::Volume>
L<VM::EC2::Volume::StatusItem>
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
use VM::EC2::Volume::Status::Details;

use strict;

sub valid_fields {
    my $self = shift;
    return qw(status details);
}

sub details {
    my $self = shift;
    my $e    = $self->SUPER::details or return;
    my @e    = map { VM::EC2::Volume::Status::Details->new($_,$self->ec2)} @{$e->{item}};
    return @e;
}

sub short_name {shift->status}

1;

