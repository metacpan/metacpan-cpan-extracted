package VM::EC2::DB::AvailabilityZone;

=head1 NAME

VM::EC2::DB::AvailabilityZone - An RDS Database Availability Zone

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 @options = $ec2->describe_orderable_db_instance_options(-engine => 'mysql');
 foreach $option (grep { $_->DBInstanceClass eq 'db.m2.4xlarge' } @options) {
   foreach $zone (grep { $_->ProvisionedIopsCapable } $option->AvailabilityZones) {
     print $option->Engine,' ',$option->EngineVersion,' ',$zone,"\n";
   }
 }

=head1 DESCRIPTION

This object represents an Availability Zone as part of an Orderable DB Instance
Option.  Return as an element of a VM::EC2->describe_orderable_db_instance_options()
call.

=head1 STRING OVERLOADING

In string context, the object returns the Availability Zone name.

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

use overload '""' => sub { shift->Name },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(Name ProvisionedIopsCapable);
}

sub ProvisionedIopsCapable {
    my $self = shift;
    my $p = $self->SUPER::ProvisionedIopsCapable;
    return $p eq 'true';
}

1;
