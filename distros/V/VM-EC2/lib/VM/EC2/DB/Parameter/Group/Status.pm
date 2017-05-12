package VM::EC2::DB::Parameter::Group::Status;

=head1 NAME

VM::EC2::DB::Parameter::Group::Status - An RDS Database Parameter Group Status object

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 $db = $ec2->create_db_instance(...);
 @param_status = $db->DBParameterGroups;
 print $_->DBParameterGroupName,'=',$_->ParameterApplyStatus,"\n" foreach @status;

=head1 DESCRIPTION

This object represents a DB Parameter Group Status.  It is returned
as an element by the following calls:
create_db_instance(), create_db_instance_read_replica(), delete_db_instance(),
modify_db_instance(), reboot_db_instance(), and 
restore_db_instance_from_db_snapshot().

=head1 METHODS

 DBParameterGroupName        --  The Parameter Group Name

 ParameterApplyStatus        --  The Status of the Parameter Group

 parameter_group             --  Provides a VM::EC2::DB::Parameter::Group object

=head1 STRING OVERLOADING

In string context, the object returns the Parameter Apply Status.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::DB::Instance>
L<VM::EC2::DB::Parameter::Group>

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
use VM::EC2::DB::Parameter::Group;

use overload '""' => sub { shift->ParameterApplyStatus },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(DBParameterGroupName ParameterApplyStatus);
}

sub parameter_group {
    my $self = shift;
    my $name = $self->DBParameterGroupName or return;
    return $self->aws->describe_db_parameter_groups(-db_parameter_group_name => $name);
}

1;
