package VM::EC2::DB::Parameter::Group;

=head1 NAME

VM::EC2::DB::Parameter::Group - An RDS Database Parameter Group

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 my @grps = $ec2->describe_db_parameter_groups();
 print $_,"\n" foreach @grps;

=head1 DESCRIPTION

This object represents a DB Parameter Group.  It is the result of a
VM::EC2->create_db_parameter_group and VM::EC2->describe_db_parameter_groups
call and is an element returned by other calls.

=head1 STRING OVERLOADING

In string context, the object returns the Parameter Group Name.

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

use overload '""' => sub { shift->DBParameterGroupName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(DBParameterGroupFamily DBParameterGroupName Description);
}

sub family { shift->DBParameterGroupFamily }

sub name { shift->DBParameterGroupName }

1;
