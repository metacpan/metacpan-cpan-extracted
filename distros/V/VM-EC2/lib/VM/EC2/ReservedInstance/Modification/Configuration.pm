package VM::EC2::ReservedInstance::Modification::Configuration;

=head1 NAME

VM::EC2::ReservedInstance::Modification::Configuration - Object describing an
Amazon EC2 reserved instance listing modification result configuration

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @mods = $ec2->describe_reserved_instances_modifications();
  for my $m (@mods) {
    my $result = $m->modificationResult,"\n";
    my $cfg = $result->targetConfiguration;
    print $cfg->availabilityZone;
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance modification result
configuration returned by VM::EC2->describe_reserved_instances_modifications().

=head1 METHODS

These object methods are supported:

 availabilityZone   -- The Availability Zone for the modified Reserved Instances

 platform           -- The network platform of the modified Reserved Instances,
                       which is either EC2-Classic or EC2-VPC

 instanceCount      -- The number of modified Reserved Instances

 instanceType       -- The instance type for the modified Reserved Instances

=head1 STRING OVERLOADING

When used in a string context, this object will return a string containing the
availabilityZone,platform,instanceCount,instanceType

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.com<gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

use overload
    '""'     => sub {
        my $self = shift;
        return $self->availabilityZone . ',' .
               $self->platform . ',' .
               $self->instanceCount . ',' .
               $self->instanceType . ',';
        },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(availabilityZone platform instanceCount instanceType);
}

1;
