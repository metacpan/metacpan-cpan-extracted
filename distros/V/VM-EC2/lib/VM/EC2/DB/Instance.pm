package VM::EC2::DB::Instance;

=head1 NAME

VM::EC2::DB::Instance - Object describing an Amazon RDS instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $db = $ec2->describe_db_instances('mydbinstance');
  
  $auto_upgrade = $db->AutoMinorVersionUpgrade;
  $az = $db->AvailabilityZone;
  $bkup_days = $db->BackupRetentionPeriod;
  $charset = $db->CharacterSetName;
  $class = $db->DBInstanceClass;
  $status = $db->DBInstanceStatus;
  $db_name = $db->DBName;
  @parm_grps = $db->DBParameterGroups;
  @sec_grps = $db->DBSecurityGroups;
  @subnet_grps = $db->DBSecurityGroups;
  $endpt = $db->Endpoint;
  $engine = $db->Engine;
  $version = $db->EngineVersion;
  $create_time = $db->InstanceCreateTime;
  $iops = $db->Iops;
  $latest_restorable_time = $db->LatestRestorableTime;
  $license = $db->LicenseModel;
  $user = $db->MasterUsername;
  $multi_az = $db->MultiAZ;
  @option_grp_memberships = $db->OptionGroupMemberships;
  @pending_vals = $db->PendingModifiedValues;
  $backup_window = $db->PreferredBackupWindow; 
  $maint_window = $db->PreferredMaintenanceWindow;
  $publicly_accessible = $db->PubliclyAccessible;
  @ids = $db->ReadReplicaDBInstanceIdentifiers;
  $id = $db->ReadReplicaSourceDBInstanceIdentifier;
  $sec_zone = $db->SecondaryAvailabilityZone;
  @vpc_grps = $db->VpcSecurityGroups;

=head1 DESCRIPTION

This object represents an Amazon RDS DB instance, and is returned by
VM::EC2->describe_db_instances(). In addition to methods to query the
instance's attributes, there are methods that allow you to manage the
instance's lifecycle, including start, stopping, and terminating it.

=head1 METHODS

=head1 LIFECYCLE METHODS

There is no concept of 'stopping' an RDS instance other than deletion.
In this sense an RDS instance is much different than an EC2 instance.
Rebooting is possible and the only means to apply some changes to the
database.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
DBInstanceIdentifier.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

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
use Carp 'croak';
use VM::EC2::DB::Parameter::Group::Status;
use VM::EC2::DB::SecurityGroup::Membership;
use VM::EC2::DB::Endpoint;
use VM::EC2::DB::PendingModifiedValues;

use overload '""' => sub { shift->DBInstanceIdentifier },
    fallback => 1;

sub valid_fields {
    my $self  = shift;
    return qw(AllocatedStorage
              AutoMinorVersionUpgrade
              AvailabilityZone
              BackupRetentionPeriod
              CharacterSetName
              DBInstanceClass
              DBInstanceIdentifier
              DBInstanceStatus
              DBName
              DBParameterGroups
              DBSecurityGroups
              DBSubnetGroup
              Endpoint
              Engine
              EngineVersion
              InstanceCreateTime
              Iops
              LatestRestorableTime
              LicenseModel
              MasterUsername
              MultiAZ
              OptionGroupMemberships
              PendingModifiedValues
              PreferredBackupWindow
              PreferredMaintenanceWindow
              PubliclyAccessible
              ReadReplicaDBInstanceIdentifiers
              ReadReplicaSourceDBInstanceIdentifier
              SecondaryAvailabilityZone
              VpcSecurityGroups
             );
}

sub AutoMinorVersionUpgrade {
    my $self = shift;
    my $auto = $self->SUPER::AutoMinorVersionUpgrade;
    return $auto eq 'true';
}

sub MultiAZ {
    my $self = shift;
    my $multi = $self->SUPER::MultiAZ;
    return $multi eq 'true';
}

sub DBParameterGroups {
    my $self = shift;
    my $groups = $self->SUPER::DBParameterGroups;
    return unless $groups;
    $groups = $groups->{DBParameterGroup};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::Parameter::Group::Status->new($groups,$self->aws)) :
        map { VM::EC2::DB::Parameter::Group::Status->new($_,$self->aws) } @$groups;
}

sub DBSecurityGroups {
    my $self = shift;
    my $groups = $self->SUPER::DBSecurityGroups;
    return unless $groups;
    $groups = $groups->{DBSecurityGroup};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::SecurityGroup::Membership->new($groups,$self->aws)) :
        map { VM::EC2::DB::SecurityGroup::Membership->new($_,$self->aws) } @$groups;
}

sub DBSubnetGroup {
    my $self = shift;
    my $group = $self->SUPER::DBSubnetGroup;
    return unless $group;
    return VM::EC2::DB::Subnet::Group->new($group->{DBSubnetGroup},$self->aws);
}

sub Endpoint {
    my $self = shift;
    my $endpoint = $self->SUPER::Endpoint;
    return VM::EC2::DB::EndPoint->new($endpoint,$self->aws);
}

sub OptionGroupMemberships {
    my $self = shift;
    my $groups = $self->SUPER::OptionGroupMemberships;
    return unless $groups;
    $groups = $groups->{OptionGroupMembership};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::Option::Group::Membership->new($groups,$self->aws)) :
        map { VM::EC2::DB::Option::Group::Membership->new($_,$self->aws) } @$groups;
}

sub PendingModifiedValues {
    my $self = shift;
    my $values = $self->SUPER::PendingModifiedValues;
    return VM::EC2::DB::PendingModifiedValues->new($values,$self->aws);
}

sub PubliclyAccessible {
    my $self = shift;
    my $public = $self->SUPER::PubliclyAccessible;
    return $public eq 'true';
}

sub VpcSecurityGroups {
    my $self = shift;
    my $groups = $self->SUPER::VpcSecurityGroups;
    return unless $groups;
    $groups = $groups->{VpcSecurityGroup};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::VpcSecurityGroup::Membership->new($groups,$self->aws)) :
        map { VM::EC2::DB::VpcSecurityGroup::Membership->new($_,$self->aws) } @$groups;
}

1;
