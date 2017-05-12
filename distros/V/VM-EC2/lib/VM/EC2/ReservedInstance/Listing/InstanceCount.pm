package VM::EC2::ReservedInstance::Listing::InstanceCounts;

=head1 NAME

VM::EC2::ReservedInstance::Listing::InstanceCounts - Object describing an Amazon EC2 
reserved instance listing instance counts

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @listings = $ec2->describe_reserved_instances_listings();
  for my $l (@listings) {
    foreach ($l->instanceCounts) {
      print $_,"\n";
    }
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance listing instance count

=head1 METHODS

These object methods are supported:

 state               -- The state of the listed Reserved Instances
                        Valid values: available | sold | cancelled | pending
 
 instanceCount       -- The number of listed Reserved Instances in the state specified by the state

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
reservedInstancesListingId.

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
        return $self->state . ' : ' . $self->instanceCount },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(state instanceCount);
}

1;
