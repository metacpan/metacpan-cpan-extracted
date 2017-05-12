package VM::EC2::DB::Option::Group::Membership;

=head1 NAME

VM::EC2::DB::Option::Group::Membership - An RDS Database Option Group Membership

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 ($db) = $ec2->describe_db_instances(-db_instance_identifier => 'mydb');
 print $_,"\n" foreach $db->OptionGroupMemberships;

=head1 DESCRIPTION

This object represents and Option Group Membership.

=head1 STRING OVERLOADING

In string context, the object returns the Option Group Name.

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


use overload '""' => sub { shift->OptionGroupName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(OptionGroupName Status);
}

1;
