package VM::EC2::DB::Event;

=head1 NAME

VM::EC2::DB::Event - An RDS Database Event

=head1 SYNOPSIS

 use VM::EC2;
 $ec2 = VM::EC2->new(...);
 my @events = $ec2->describe_events;
 print $_,"\n" foreach grep { $_->SourceIdentifier eq 'mydbinstance' } @events;

=head1 DESCRIPTION

This object represents an event related to DB instances, DB security groups, 
DB snapshots, and DB parameter groups that have happened in the past 14 days.

=head1 STRING OVERLOADING

In string context, this object returns a string with the date,
identifier of the source of the event, and the event message.

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
    return qw(Date EventCategories Message SourceIdentifier SourceType);
}

sub EventCategories {
    my $self = shift;
    my $cats = $self->SUPER::EventCategories;
    return unless $cats;
    $cats = $cats->{EventCategory};
    return ref $cats eq 'ARRAY' ? @$cats : ($cats);
}

sub as_string {
    my $self = shift;
    return $self->Date . '[ ' . $self->SourceIdentifier . ' ] ' . $self->Message;
}

1;
