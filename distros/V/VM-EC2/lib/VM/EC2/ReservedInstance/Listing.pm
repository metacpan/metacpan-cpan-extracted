package VM::EC2::ReservedInstance::Listing;

=head1 NAME

VM::EC2::ReservedInstance::Listing - Object describing an Amazon EC2 reserved instance listing

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @listings = $ec2->describe_reserved_instances_listings();
  for my $l (@listings) {
    print $l->reservedInstancesId,"\n";
    print $l->createDate,"\n";
    print $l->status,"\n";
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance listing, as
returned by VM::EC2->describe_reserved_instances_listings().

=head1 METHODS

These object methods are supported:

 reservedInstancesListingId  -- ID of this listing

 reservedInstancesId         -- The ID of the Reserved Instance
 
 createDate                  -- The time the listing was created

 updateDate                  -- The last modified timestamp of the listing

 status                      -- The status of the Reserved Instance listing
                                Valid values:
                                 active | pending | cancelled | closed

 statusMessage               -- The reason for the current status of the listing
                                The response can be blank.

 instanceCounts              -- Number of instances in this state

 priceSchedules              -- Price of the Reserved Instance listing

 clientToken                 -- The idempotency token you provided when you
                                created the listing

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
use VM::EC2::ReservedInstance::Listing::InstanceCount;
use VM::EC2::ReservedInstance::Listing::PriceSchedule;

use overload
    '""'     => sub {
        my $self = shift;
        return $self->reservedInstancesListingId },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(reservedInstancesListingId reservedInstancesId createDate
              updateDate status statusMessage instanceCounts 
              priceSchedules clientToken);
}

sub instanceCounts {
    my $self = shift;
    my $ic = $self->SUPER::instanceCounts or return;
    return map { VM::EC2::ReservedInstance::Listing::InstanceCount->new($_,$self->aws,$self->xmlns,$self->requestId) }
           @{$ic->{item}};
}

sub priceSchedules {
    my $self = shift;
    my $ps = $self->SUPER::priceSchedules or return;
    return map { VM::EC2::ReservedInstance::Listing::PriceSchedule->new($_,$self->aws,$self->xmlns,$self->requestId) }
           @{$ps->{item}};
}

1;
