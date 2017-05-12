package VM::EC2::DB::Reserved::Instance;

=head1 NAME

VM::EC2::DB::Reserved::Instance - An RDS Database Reserved Instance

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 @i = $ec2->describe_reserved_db_instances;
 print "$_\n" foreach grep { $_->State eq 'active' } @i;

=head1 DESCRIPTION

This object represents an RDS Reserved DB Instance.

=head1 STRING OVERLOADING

In string context, this object outputs 

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
        DBInstanceCount
        Duration
        FixedPrice
        MultiAZ
        OfferingType
        ProductDescription
        RecurringCharges
        ReservedDBInstanceId
        ReservedDBInstancesOfferingId
        StartTime
        State
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
    push @fields, sprintf('%3i',$self->DBInstanceCount);
    push @fields, $self->ReservedDBInstanceId,
    push @fields, sprintf('%25s',$self->StartTime);
    push @fields, sprintf('%18s',$self->OfferingType);
    push @fields, sprintf('%4i Days',$self->Duration / 86400);
    push @fields, sprintf('%13s',$self->DBInstanceClass);
    push @fields, sprintf('%9s',$self->MultiAZ ? 'Multi AZ' : 'Single AZ');
    push @fields, sprintf('%s%8s',$self->CurrencyCode,sprintf('%.2f',$self->FixedPrice));
    push @fields, sprintf('%s%6s/Hourly',$self->CurrencyCode,sprintf('%.3f',$self->UsagePrice));
    push @fields, $self->RecurringCharges ? sprintf('%s%6s/' . $self->RecurringCharges->frequency,$self->CurrencyCode,sprintf('%.3f',$self->RecurringCharges->amount)) : ' ' x 16;
    push @fields, $self->ProductDescription;
    push @fields, $self->ReservedDBInstancesOfferingId;
    push @fields, sprintf('%15s',$self->State);
    return join($delim,@fields)
}

1;
