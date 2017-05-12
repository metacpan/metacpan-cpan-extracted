package VM::EC2::DB::PendingModifiedValues;

=head1 NAME

VM::EC2::DB::PendingModifiedValues - An RDS Database Pending Modifed Values object

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 $db = $ec2->modify_db_instance(...);
 $pending = $db->PendingModifiedValues;
 foreach $p ($pending->valid_fields) {
    print $p,' ',$pending->$p,"\n" if $pending->$p;
 }

=head1 DESCRIPTION

This object represents the changes to a DB instance that are currently pending.

=head1 STRING OVERLOADING

none

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

sub valid_fields {
    my $self = shift;
    return qw(
        AllocatedStorage
        BackupRetentionPeriod
        DBInstanceClass
        DBInstanceIdentifier
        EngineVersion
        Iops
        MasterUserPassword
        MultiAZ
        Port
    );
}

sub MultiAZ {
    my $self = shift;
    my $multi_az = $self->SUPER::MultiAZ;
    return $multi_az eq 'true';
}

1;
