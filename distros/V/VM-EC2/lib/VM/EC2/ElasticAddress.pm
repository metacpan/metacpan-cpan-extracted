package VM::EC2::ElasticAddress;

=head1 NAME

VM::EC2::ElasticAddress - Object describing an Amazon EC2 Elastic Address

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  $addr    = $ec2->allocate_address;

  $ip      = $addr->publicIp;
  $domain  = $addr->domain;
  $allId   = $addr->allocationId;

=head1 DESCRIPTION

This object represents an Amazon EC2 elastic address and is returned by
by VM::EC2->allocate_address().

=head1 METHODS

These object methods are supported:

 publicIp      -- Public IP of the address
 domain        -- Type of address, either "standard" or "vpc"
 allocationId  -- For VPC addresses only, an allocation ID
 instanceId    -- If the address is associated with an instance, the
                  ID of that instance.
 associationId -- If the address is a VPC elastic IP, and associated
                  with an instance, then the ID of the association.

In addition, the following convenience methods are provided:

=head2 $result = $addr->associate($instance_id)

Associate this address with the given instance ID or
VM::EC2::Instance object. If successful, the result code will be
true for an ordinary EC2 Elastic IP,or equal to the associationId for
a VPC Elastic IP address.

=head2 $result = $addr->disassociate()

Disassociate this address with any instance it is already associated
with. If successful, this method will return true.

=head2 $addr->refresh()

This is an internal function called after associate() and
disassociate(), and is used to refresh the address object's contents.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
publicIp.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>

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

sub primary_id {shift->publicIp}

sub valid_fields {
    my $self = shift;
    return qw(publicIp domain allocationId instanceId associationId);
}

sub associate {
    my $self = shift;
    my $instance = shift or die "Usage: \$elastic_addr->associate(\$instance)";
    my $result = $self->aws->associate_address($self,$instance);
    $self->refresh if $result;
    $result;
}

sub disassociate {
    my $self = shift;
    my $result = $self->aws->disassociate_address($self);
    $self->refresh if $result;
    $result;
}

sub refresh {
    my $self = shift;
    my $i  = $self->aws->describe_addresses($self);
    %$self = %$i if $i;
    return defined $i;
}

1;
