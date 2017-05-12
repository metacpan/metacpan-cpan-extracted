package VM::EC2::DB::EC2SecurityGroup;

=head1 NAME

VM::EC2::DB::EC2SecurityGroup - An RDS Database EC2 Security Group

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 $group = $ec2->authorize_db_security_group_ingress(-db_security_group_name => 'dbgroup',
                                                    -ec2_security_group_name => 'ec2group',
                                                    -ec2_security_group_owner_id => '123456789123');
 print $_,"\n" foreach $group->EC2SecurityGroups;

=head1 DESCRIPTION

This object represents an EC2 Security Group that is authorized in a DB Security Group.

=head1 STRING OVERLOADING

In string context, this object returns the EC2 Security Group ID.

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

use overload '""' => sub { shift->EC2SecurityGroupId },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(EC2SecurityGroupId EC2SecurityGroupName EC2SecurityGroupOwnerId Status);
}

sub group_id { shift->EC2SecurityGroupId }

sub group_name { shift->EC2SecurityGroupName }

sub owner_id { shift->EC2SecurityGroupOwnerId }

1;
