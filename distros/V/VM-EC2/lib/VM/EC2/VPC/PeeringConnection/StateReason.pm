package VM::EC2::VPC::PeeringConnection::StateReason;

=head1 NAME

VM::EC2::VPC::PeeringConnection::StateReason - Virtual Private Cloud Peering
Connection State Reason

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2   = VM::EC2->new(...);
 my $pcx = $ec2->describe_vpc_peering_connections(-vpc_peering_connection_id=>'pcx-12345678');
 my $status = $pcx->status;
 print $status->message,"\n";

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC Peering Connection State Reason as returned in
a VPC Peering Connection.

=head1 METHODS

These object methods are supported:

 code          -- The status code of the VPC peering connection
                  Valid values:
                    initiating-request | pending-acceptance | failed | expired |
                    provisioning | active | deleted | rejected
 message       -- A message that provides more information about the status,
                  if applicable

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate a string containing
the code and message in format "[code] message"

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::VPC>
L<VM::EC2::VPC::PeeringConnection>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use Carp 'croak';

use overload '""' => sub { shift->as_string },
    fallback => 1;

sub valid_fields {
    my $self  = shift;
    return qw(code message);
}

sub as_string {
    my $self = shift;
    return '[' . $self->code . '] ' . $self->message;
}

1;
