package VM::EC2::ReservedInstance::Modification;

=head1 NAME

VM::EC2::ReservedInstance::Modification - Object describing an Amazon EC2
reserved instance listing modification

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @mods = $ec2->describe_reserved_instances_modifications();
  for my $m (@mods) {
    print $m->reservedInstancesModificationId,"\n";
    print $m->createDate,"\n";
    print $m->status,"\n";
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance modification, as
returned by VM::EC2->describe_reserved_instances_modifications().

=head1 METHODS

These object methods are supported:

 reservedInstancesModificationId  -- ID of this modification

 clientToken                      -- The idempotency token you provided when you
                                     created the listing

 reservedInstancesId              -- The ID of the Reserved Instance
 
 modificationResult               -- Contains target configurations along with
                                     their corresponding new Reserved Instance
                                     IDs

 createDate                       -- The time when the modification request was
                                     created

 updateDate                       -- Time when the modification request was last
                                     updated

 effectiveDate                    -- Time for the modification to become
                                     effective

 status                           -- The status of the Reserved Instances
                                     modification request
                                     Valid values:
                                      processing | fulfilled | failed

 statusMessage                    -- The reason for the current status
                                     
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
use VM::EC2::ReservedInstance::Modification::Result;

use overload
    '""'     => sub {
        my $self = shift;
        return $self->reservedInstancesModificationId},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(reservedInstancesModificationId reservedInstancesId createDate
              modificationResult updateDate status statusMessage effectiveDate
              clientToken);
}

sub modificationResult {
    my $self = shift;
    my $result = $self->SUPER::modificationResult or return;

    return map { VM::EC2::ReservedInstance::Modification::Result->new($_,$self->aws,$self->xmlns,$self->requestId) }
           @{$result->{item}};
}

1;
