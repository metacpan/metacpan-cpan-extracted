package VM::EC2::DB::Reserved::RecurringCharge;

=head1 NAME

VM::EC2::DB::Reserved::RecurringCharge - An RDS Database Reserved Instance Recurring Charge

=head1 SYNOPSIS

 use VM::EC2;
 $ec2 = VM::EC2->new(...);
 @i = $ec2->describe_reserved_db_instances;
 print $_->RecurringCharges,"\n" foreach grep { $_->State eq 'active' } @i;

=head1 DESCRIPTION

This object represents a recurring charge from an RDS Reserved DB Instance or an
RDS Reserved DB Instance Offering.

=head1 STRING OVERLOADING

In string context, this object returns a string containing the recurring charge
amount and frequency.

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

use overload '""' => sub { shift->as_string },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(RecurringChargeAmount RecurringChargeFrequency);
}

sub amount { shift->RecurringChargeAmount }

sub frequency { shift->RecurringChargeFrequency }

sub as_string {
    my $self = shift;
    return $self->RecurringChargeAmount . '/' . $self->RecurringChargeFrequency;
}

1;
