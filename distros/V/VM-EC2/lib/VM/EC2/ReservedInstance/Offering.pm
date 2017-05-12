package VM::EC2::ReservedInstance::Offering;

=head1 NAME

VM::EC2::ReservedInstance::Offering - Object describing an Amazon EC2 reserved instance offering

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @offerings = $ec2->describe_reserved_instances_offerings();
  for my $o (@offerings) {
    print $o->reservedInstancesOfferingId,"\n";
    print $o->instanceType,"\n";
    print $o->availabilityZone,"\n";
    print $o->duration,"\n";
    print $o->fixedPrice,"\n";
    print $o->usagePrice,"\n";
    print $o->productDescription,"\n";
    print $o->instanceTenancy,"\n";
    print $o->currencyCode,"\n";
  }

 # purchase the first one
 $offerings[0]->purchase() && print "offer purchased\n";

=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance offering, as
returned by VM::EC2->describe_reserved_instances_offerings.

=head1 METHODS

These object methods are supported:

 reservedInstancesOfferingId -- ID of this offer
 
 instanceType                -- The instance type on which this reserved
                                 instance can be used.

 availabilityZone            -- The availability zone in which this reserved
                                 instance can be used.

 duration                    -- The duration of the reserved instance contract, in seconds.

 fixedPrice                  -- The purchase price of the reserved instance for the indicated
                                 version.

 usagePrice                  -- The usage price of the reserved instance, per hour.

 productDescription          -- The reserved instance description. One of  "Linux/UNIX",
                                 "Linux/UNIX (Amazon VPC)", "Windows", and "Windows (Amazon
                                   VPC)"

 instanceTenancy             -- The tenancy of the reserved instance (VPC only).

 currencyCode                -- The currency of the reserved instance offering prices.

In addition, this object supports the purchase() method:

=head2 $boolean = $offering->purchase($count)

Purchases the offering and returns true on success. The optional
$count argument specifies the number of reserved instances to purchase
(default 1).

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
reservedInstancesOfferingId.

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

sub primary_id {shift->reservedInstancesOfferingId}

sub valid_fields {
    my $self = shift;
    return qw(reservedInstancesOfferingId instanceType availabilityZone
              duration fixedPrice usagePrice productDescription instanceTenancy
              currencyCode);
}

sub purchase {
    my $self = shift;
    my $count = shift || 1;
    return $self->ec2->purchase_reserved_instances_offering
	(-instance_count=>$count,
	 -reserved_instances_offering_id=>$self->reservedInstancesOfferingId
	);
}

1;
