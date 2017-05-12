package VM::EC2::ELB::PolicyTypeDescription;

=head1 NAME

VM::EC2::ELB::PolicyTypeDescription - Elastic Load Balancer Policy Type

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2          = VM::EC2->new(...);
 my @policy_types = $ec2->describe_load_balancer_policy_types;

=head1 DESCRIPTION

This object is used to represent the PolicyTypeDescription data type, which 
is in the result of a DescribeLoadBalancerPolicyTypes ELB API call.

=head1 METHODS

The following object methods are supported:
 
 PolicyTypeName                  -- The policy type name
 Description                     -- Description
 PolicyAttributeTypeDescriptions -- A series of L<VM::EC2::ELB::PolicyAttributeType>
                                    objects
 attribute_types                 -- Alias for PolicyAttributeTypeDescriptions

=head1 STRING OVERLOADING

In string context, the object returns the Policy Type Name.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>
L<VM::EC2::ELB::PolicyAttributeTypeDescription>

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
use VM::EC2::ELB::PolicyAttributeType;

use overload
    '""'     => sub { shift->PolicyTypeName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(Description PolicyAttributeTypeDescriptions PolicyTypeName);
}

sub PolicyAttributeTypeDescriptions {
    my $self = shift;
    my $patd = $self->SUPER::PolicyAttributeTypeDescriptions;
    return map { VM::EC2::ELB::PolicyAttributeType->new($_,$self->aws) } @{$patd->{member}};
}

sub attribute_types { shift->PolicyAttributeTypeDescriptions }

1;
