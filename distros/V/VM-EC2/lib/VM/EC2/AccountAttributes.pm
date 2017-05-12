package VM::EC2::AccountAttributes;

=head1 NAME

VM::EC2::AccountAttributes - Object describing an Amazon EC2 account attributes set

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $attr     = $ec2->describe_account_attributes('default-vpc');
  print $attr->name,' : ',join(',',$attr->values),"\n";

=head1 DESCRIPTION

This object represents values of a account attribute

=head1 METHODS

These object methods are supported:
 AttributeName     -- The attribute name
 AttributeValueSet -- The attribute value set
 name              -- alias for AttributeName
 values            -- returns array of values returned in AttributeValueSet

=head1 STRING OVERLOADING

When used in a string context, this object will return a string containing
the name and values for the format name=value1,value2,etc

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Object>
L<VM::EC2::Generic>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2013 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub primary_id {
    my $self = shift;
    return $self->name . '=' . join(',',$self->values)
}

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(attributeName attributeValueSet);
}

sub values {
    my $self = shift;
    my $set = $self->attributeValueSet;
    my $values = $set->{item};
    return map { $_->{attributeValue} } @$values
}

sub name { shift->attributeName }

1;

