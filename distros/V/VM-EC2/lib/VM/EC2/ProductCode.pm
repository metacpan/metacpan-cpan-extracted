package VM::EC2::ProductCode;

=head1 NAME

VM::EC2::ProductCode - Object describing an Amazon EC2 product code

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $volume = $ec2->describe_volumes('vol-123456');
  for my $g ($volume->product_codes) {
    my $id      = $g->productCode;
    my $type    = $g->type;
  }

=head1 DESCRIPTION

This object represents the code and type of a product code.

=head1 METHODS

These object methods are supported:

 productCode   -- the product code
 code          -- shorter version of the above
 type          -- the type of product code ('devpay','marketplace')

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
productCode

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Object>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::Volume>

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

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(productCode type);
}

sub code { shift->productCode }
sub short_name {shift->productCode}

1;

