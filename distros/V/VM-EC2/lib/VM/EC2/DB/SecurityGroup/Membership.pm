package VM::EC2::DB::SecurityGroup::Membership;

=head1 NAME

VM::EC2::DB::SecurityGroup::Membership - An RDS Database Security Group Membership

=head1 SYNOPSIS

 use VM::EC2;
 $ec2 = VM::EC2->new(...);
 my $db = $ec2->describe_db_instance(...);
 my @grps = $db->DBSecurityGroups;

=head1 METHODS

 DBSecurityGroupName        -- The security group name

 Status                     -- The security group status

 name                       -- Alias for DBSecurityGroupName

 status                     -- Alias for Status

 db_security_group          -- returns an VM::EC2::DB::SecurityGroup object

=head1 DESCRIPTION

This object describes a DB Security Group Membership.  It is a response element
in calls that return a DB instance object.

=head1 STRING OVERLOADING

In string context, the object returns the Security Group Name.

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

use overload '""' => sub { shift->DBSecurityGroupName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(DBSecurityGroupName Status);
}

sub name { shift->DBSecurityGroupName }

sub status { shift->Status }

sub db_security_group {
    my $self = shift;
    my $name = $self->DBSecurityGroupName or return;
    return $self->aws->describe_db_security_groups(-db_security_group_name => $name);
}

1;
