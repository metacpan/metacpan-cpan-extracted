package VM::EC2::PlacementGroup;

=head1 NAME

VM::EC2::PlacementGroup - Object describing an Amazon EC2 cluster
placement group

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $group = $ec2->describe_placement_groups(-group_name=>'clusterXYZ');
  $state = $group->state;

=head1 DESCRIPTION

This object represents a cluster placement group.

=head1 METHODS

These object methods are supported:

 groupName -- the group's name
 strategy  -- the placement strategy
              valid values:
               cluster
 state     -- the state of the placement group
              valid values:
               pending | available | deleting | deleted

In addition, this object supports the delete() method.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
groupName.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Object>
L<VM::EC2::Generic>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(groupName strategy state);
}

sub primary_id { shift->groupName }

sub delete {
    my $self = shift;
    $self->aws->delete_placement_group($self->groupName)
}

1;

