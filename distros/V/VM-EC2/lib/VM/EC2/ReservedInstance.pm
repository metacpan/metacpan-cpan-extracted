package VM::EC2::ReservedInstance;

=head1 NAME

VM::EC2::ReservedInstance - Object describing an Amazon EC2 reserved instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @offerings = $ec2->describe_reserved_instances();
  for my $o (@offerings) {
    print $o->reservedInstancesId,"\n";
    print $o->instanceType,"\n";
    print $o->availabilityZone,"\n";
    print $o->start,"\n";
    print $o->duration,"\n";
    print $o->fixedPrice,"\n";
    print $o->usagePrice,"\n";
    print $o->instanceCount,"\n";
    print $o->productDescription,"\n";
    print $o->state,"\n";
    print $o->instanceTenancy,"\n";
    print $o->currencyCode,"\n";
    $tags = $o->tags;
  }
=head1 DESCRIPTION

This object represents an Amazon EC2 reserved instance reservation
that you have purchased, as returned by
VM::EC2->describe_reserved_instances().

=head1 METHODS

These object methods are supported:

 reservedInstancesId -- ID of this reserved instance contract
 
 instanceType        -- The instance type on which these reserved
                         instance can be used.

 availabilityZone    -- The availability zone in which these reserved
                         instances can be used.

 start               -- The date and time that this contract was established.

 duration            -- The duration of this contract, in seconds.

 fixedPrice          -- The purchase price of the reserved instance for the indicated
                         version.

 usagePrice          -- The usage price of the reserved instance, per hour.

 instanceCount       -- The number of instances that were purchased under this contract.

 productDescription  -- The reserved instance description. One of  "Linux/UNIX",
                         "Linux/UNIX (Amazon VPC)", "Windows", and "Windows (Amazon VPC)"

 state               -- The state of the reserved instance purchase. One of "payment-pending",
                         "active", "payment-failed", and "retired".

 tagSet              -- Tags for this reserved instance set. More conveniently accessed via
                         the tags(), add_tags() and delete_tags() methods.

 instanceTenancy     -- The tenancy of the reserved instance (VPC only).

 currencyCode        -- The currency of the reserved instance offering prices.

This object supports the various tag manipulation methods described in
L<VM::EC2::Generic>. In addition it supports the following methods:

=head2 $status = $reserved_instance->current_status

Refreshes the object and returns its state, one of "payment-pending",
"active", "payment-failed", and "retired". You can use this to monitor
the progress of a purchase.

=head2 $reserved_instance->refresh

Calls VM::EC2->describe_reserved_instances() to refresh the object
against current information in Amazon.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
reservedInstancesId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ReservedInstances::Offering>

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

sub primary_id {shift->reservedInstancesId}

sub valid_fields {
    my $self = shift;
    return qw(reservedInstancesId instanceType availabilityZone
              start duration fixedPrice usagePrice instanceCount
              productDescription state tagSet instanceTenancy
              currencyCode);
}

sub current_status {
    my $self = shift;
    $self->refresh;
    return $self->state;
}

sub current_state { shift->current_status } # alias

sub refresh {
    my $self = shift;
    my $i = $self->ec2->describe_reserved_instances($self->reservedInstancesId);
    %$self = %$i if $i;
    return defined $i;
}


1;
