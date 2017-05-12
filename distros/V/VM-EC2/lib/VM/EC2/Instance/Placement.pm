package VM::EC2::Instance::Placement;

=head1 NAME

VM::EC2::Instance::Placement - Object describing an Amazon EC2 instance's placement

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);

=head1 DESCRIPTION

This object represents the placement of an instance in an Amazon EC2 availability region
and cluster group. It is returned by VM::EC2->describe_instances

=head1 METHODS

These object methods are supported:

  availabilityZone   -- The availability zone of the instance.
  groupName          -- The name of the placement group in a
                        cluster computing instance.
  tenancy            -- Tenancy of the instance, e.g. "dedicated".

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
availabilityZone.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

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

use overload 
    '""'     => sub {shift()->availabilityZone},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(availabilityZone groupName tenancy);
}

1;
