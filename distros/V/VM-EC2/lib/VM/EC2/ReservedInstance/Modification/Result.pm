package VM::EC2::ReservedInstance::Modification::Result;

=head1 NAME

VM::EC2::ReservedInstance::Modification::Result - Object describing an Amazon
EC2 reserved instance listing modification result

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @mods = $ec2->describe_reserved_instances_modifications();
  for my $m (@mods) {
    print $m->modificationResult,"\n";
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance modification result,
returned by VM::EC2->describe_reserved_instances_modifications().

=head1 METHODS

These object methods are supported:

 reservedInstancesId              -- The ID of the reserved instance

 targetConfiguration              -- The configuration of the reserved instance

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
reservedInstancesModificationId

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
use VM::EC2::ReservedInstance::Modification::Configuration;

use overload
    '""'     => sub {
        my $self = shift;
        return $self->reservedInstancesId},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(reservedInstancesId targetConfiguration);
}

sub targetConfiguration {
    my $self = shift;
    my $tc = $self->SUPER::targetConfiguration or return;

    return VM::EC2::ReservedInstance::Modification::Configuration->new($tc,$self->aws,$self->xmlns,$self->requestId);
}

1;
