package VM::EC2::Instance::IamProfile;

=head1 NAME

VM::EC2::Instance::IamProfile - Object describing an Amazon EC2 Identity Access Management profile

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  my $instance = $ec2->describe_instances('i-123456');
  my $profile  = $instance->iamInstanceProfile;
  print $profile->arn,"\n";
  print $profile->id,"\n";
 
=head1 DESCRIPTION

This object represents an Amazon IAM profile associated with an instance.

=head1 METHODS

These object methods are supported:

 arn    The Amazon resource name (ARN) of the IAM Instance Profile (IIP)
        associated with the instance.
 id     The ID of the IIP associated with the instance.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
arn.

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

sub short_name {shift->arn};

sub valid_fields {
    my $self = shift;
    return qw(arn id);
}

1;
