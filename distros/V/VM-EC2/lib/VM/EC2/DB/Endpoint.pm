package VM::EC2::DB::Endpoint;

=head1 NAME

VM::EC2::DB::Endpoint - An RDS Database Endpoint

=head1 SYNOPSIS

 use VM::EC2;
 ($i) = $ec2->describe_db_instances(-db_instance_identifier => 'mydb');
 print $i->Endpoint,"\n";

=head1 DESCRIPTION

This object represents the endpoint of a DB Instance.

=head1 STRING OVERLOADING

In string context, this object returns a string containing the Address
and Port of the endpoint in the form 'Address:Port'.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::DB::Instance>

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

use overload '""' => sub { shift->as_string },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(Address Port);
}

sub as_string {
    my $self = shift;
    return $self->Address . ':' . $self->Port;
}

1;
