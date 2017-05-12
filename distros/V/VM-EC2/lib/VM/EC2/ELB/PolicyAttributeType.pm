package VM::EC2::ELB::PolicyAttributeType;

=head1 NAME

VM::EC2::ELB::PolicyAttributeType - Load Balancer Policy Attribute Type

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2          = VM::EC2->new(...);
 my @policy_types = $ec2->describe_load_balancer_policy_types;
 foreach my $type (@policy_types) {
     print $type,': ',$type->Description,"\n";
     foreach ($type->attribute_types) {
         print $_->AttributeName,"\n ",
               $_->AttributeType,"\n ",
               $_->Cardinality,"\n ",
               $_->DefaultValue,"\n ",
               $_->Description,"\n ";
     }
 }

=head1 DESCRIPTION

This object is used to describe the ELB PolicyAttributeTypeDescription data
type.

=head1 METHODS

The following object methods are supported:
 
 AttributeName    -- The attribute name
 AttributeType    -- The attribute type
 Cardinality      -- Cardinality of the policy attribute
 DefaultValue     -- Default value for the attribute
 Description      -- Description of the attribute

=head1 STRING OVERLOADING

In string context, the object will return the Attribute Name.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB::PolicyType>

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

use overload
    '""'     => sub { shift->AttributeName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(AttributeName AttributeType Cardinality DefaultValue Description);
}

1;
