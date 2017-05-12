package VM::EC2::DB::Reserved::Instance::Offering;

=head1 NAME

VM::EC2::DB::Reserved::Instance::Offering - An RDS Database Reserved Instance Offering

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 my @i = $ec2->describe_reserved_db_instances_offerings;
 print "$_\n" foreach grep { $_->MultiAZ } @i;

=head1 DESCRIPTION

This object represents an RDS Reserved Instance Offering.  It is returned by
the VM::EC2->describe_reserved_db_instances_offerings() call.

=head1 STRING OVERLOADING

In string context, this object returns a formatted string containing all the data
available on the reserved instance offering.

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
use VM::EC2::DB::Reserved::RecurringCharge;

use overload '""' => sub { shift->as_string },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(
        CurrencyCode
        DBInstanceClass
        Duration
        FixedPrice
        MultiAZ
        OfferingType
        ProductDescription
        RecurringCharges
        ReservedDBInstancesOfferingId
        UsagePrice
    );
}

sub MultiAZ {
    my $self = shift;
    my $maz = $self->SUPER::MultiAZ;
    return $maz eq 'true';
}

sub RecurringCharges {
    my $self = shift;
    my $rc = $self->SUPER::RecurringCharges;
    return unless $rc;
    $rc = $rc->{RecurringCharge};
    return ref $rc eq 'HASH' ?
       (VM::EC2::DB::Reserved::RecurringCharge->new($rc,$self->aws)) :
       map { VM::EC2::DB::Reserved::RecurringCharge->new($_,$self->aws) } @$rc;
}

sub as_string {
    my $self = shift;
    my $delim = shift || '  ';
    my @fields;
    push @fields, $self->ReservedDBInstancesOfferingId;
    push @fields, sprintf('%18s',$self->OfferingType);
    push @fields, sprintf('%4i Days',$self->Duration / 86400);
    push @fields, sprintf('%13s',$self->DBInstanceClass);
    push @fields, sprintf('%9s',$self->MultiAZ ? 'Multi AZ' : 'Single AZ');
    push @fields, sprintf('%s%8s',$self->CurrencyCode,sprintf('%.2f',$self->FixedPrice));
    push @fields, sprintf('%s%6s/Hourly',$self->CurrencyCode,sprintf('%.3f',$self->UsagePrice));
    push @fields, $self->RecurringCharges ? sprintf('%s%6s/' . $self->RecurringCharges->frequency,$self->CurrencyCode,sprintf('%.3f',$self->RecurringCharges->amount)) : ' ' x 16;
    push @fields, $self->ProductDescription;
    return join($delim,@fields)
}

1;
