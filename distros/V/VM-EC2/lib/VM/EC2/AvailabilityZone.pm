package VM::EC2::AvailabilityZone;

=head1 NAME

VM::EC2::AvailabilityZone - Object describing an Amazon availability zone

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  @zones   = $ec2->describe_availability_zones(-filter=>{state=>'available'});

  $zone    = $zones[0];
  $name    = $zone->zoneName;
  @messages= $zone->messages;

=head1 DESCRIPTION

This object represents an Amazon EC2 availability zone, and is returned
by VM::EC2->describe_availability_zones().

=head1 METHODS

These object methods are supported:

 zoneName      -- Name of the zone, e.g. "eu-west-1a"
 zoneState     -- State of the availability zone, e.g. "available"
 regionName    -- Name of the region
 region        -- A VM::EC2::Region object corresponding to regionName
 messages      -- A list of messages about the zone

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
zoneName.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Region>

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

sub primary_id {shift->zoneName}

sub valid_fields {
    my $self = shift;
    return qw(zoneName zoneState regionName messageSet);
}

sub messages {
    my $self = shift;
    my $m    = $self->messageSet or return;
    return map {$_->{message}} @{$m->{item}};
}

sub region {
    my $self = shift;
    my $r    = $self->regionName;
    return $self->aws->describe_regions($r);
}

1;
