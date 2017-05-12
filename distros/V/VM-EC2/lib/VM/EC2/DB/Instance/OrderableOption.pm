package VM::EC2::DB::Instance::OrderableOption;

=head1 NAME

VM::EC2::DB::Instance::OrderableOption - An RDS Database Orderable Option

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 @options = $ec2->describe_orderable_db_instance_options(-engine => 'mysql');
 foreach $option (grep { $_->MultiAZCapable } @options) {
   print $option->EngineVersion,' ',
         $option->DBInstanceClass,' ',
         join(',',grep { $_->ProvisionedIopsCapable } $option->AvailabilityZones),
         "\n";
 }

=head1 DESCRIPTION

This object represents a DB Instance Orderable Option, as returned by the
VM::EC2->describe_orderable_db_instance_options() call.

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
use VM::EC2::DB::AvailabilityZone;

sub valid_fields {
    my $self = shift;
    return qw(
        AvailabilityZones
        DBInstanceClass
        Engine
        EngineVersion
        LicenseModel
        MultiAZCapable
        ReadReplicaCapable
        Vpc
    );
}

sub AvailabilityZones {
    my $self = shift;
    my $azs = $self->SUPER::AvailabilityZones;
    return unless $azs;
    $azs = $azs->{AvailabilityZone};
    return ref $azs eq 'HASH' ?
        (VM::EC2::DB::AvailabilityZone->new($azs,$self->aws)) :
        map { VM::EC2::DB::AvailabilityZone->new($_,$self->aws) } @$azs;
}

sub MultiAZCapable {
    my $self = shift;
    my $maz = $self->SUPER::MultiAZCapable;
    return $maz eq 'true';
}

sub ReadReplicaCapable {
    my $self = shift;
    my $r = $self->SUPER::ReadReplicaCapable;
    return $r eq 'true';
}

sub Vpc {
    my $self = shift;
    my $v = $self->SUPER::Vpc;
    return $v eq 'true';
}

1;
