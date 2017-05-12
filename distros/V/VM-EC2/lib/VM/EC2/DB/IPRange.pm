package VM::EC2::DB::IPRange;

=head1 NAME

VM::EC2::DB::IPRange - An RDS Database IP Range

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 $group = $ec2->revoke_db_security_group_ingress(-db_security_group_name => 'dbgroup',
                                                    -cidrip => '10.10.10.10/32');
 print $_,"\n" foreach grep { $_->Status eq 'authorized' } $group->IPRanges;

=head1 DESCRIPTION

This object represents an IP Range in a DB Security group.

=head1 STRING OVERLOADING

In string context, this object returns the CIDRIP.

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

use overload '""' => sub { shift->CIDRIP },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(CIDRIP Status);
}

1;
