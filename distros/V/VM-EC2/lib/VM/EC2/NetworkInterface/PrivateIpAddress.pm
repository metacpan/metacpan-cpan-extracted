package VM::EC2::NetworkInterface::PrivateIpAddress;

=head1 NAME

VM::EC2::NetworkInterface::PrivateIpAddress

=head1 SYNOPSIS

  use VM::EC2;
 ...

=head1 DESCRIPTION

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 privateIpAddress
 privateDnsName
 primary
 association

In addition, this object supports the following convenience methods:

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
VPC ID.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::NetworkInterface::Association;

sub valid_fields {
    my $self  = shift;
    return qw(privateIpAddress privateDnsName primary association);
}

sub primary {
    my $self = shift;
    my $p    = $self->SUPER::primary;
    return $p eq 'true';
}

sub short_name { shift->privateIpAddress }

sub association {
    my $self = shift;
    my $ass = $self->SUPER::association;
    return VM::EC2::NetworkInterface::Association->new($ass,$self->ec2);
}

1;

