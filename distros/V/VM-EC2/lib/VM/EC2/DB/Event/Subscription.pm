package VM::EC2::DB::Event::Subscription;

=head1 NAME

VM::EC2::DB::Event::Subscription - An RDS Database Event Subscription

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  @subs = $ec2->describe_event_subscriptions;
  @db_subs = grep { $_->SourceType eq 'db-instance' } @subs;
  @enabled = grep { $_->Enabled } @subs;

=head1 DESCRIPTION

This object represents an RDS Event Subscription.  It is the resultant
output of a VM::EC2->describe_event_subscriptions() and
VM::EC2->create_event_subscription() call.

=head1 STRING OVERLOADING

When used in a string context, this object will output the
CustSubscriptionId.

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

use overload '""' => sub { shift->CustSubscriptionId },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(
        CustSubscriptionId
        CustomerAwsId
        Enabled
        EventCategoriesList
        SnsTopicArn
        SourceIdsList
        SourceType
        Status
        SubscriptionCreationTime
    );
}

sub Enabled {
    my $self = shift;
    my $enabled = $self->SUPER::Enabled;
    return $enabled eq 'true';
}

sub EventCategoriesList {
    my $self = shift;
    my $cats = $self->SUPER::EventCategoriesList;
    return unless $cats;
    $cats = $cats->{EventCategory};
    return ref $cats eq 'ARRAY' ? @$cats : ($cats);
}

sub SourceIdsList {
    my $self = shift;
    my $ids = $self->SUPER::SourceIdsList;
    return unless $ids;
    $ids = $ids->{SourceId};
    return ref $ids eq 'ARRAY' ? @$ids: ($ids);
}

1;
