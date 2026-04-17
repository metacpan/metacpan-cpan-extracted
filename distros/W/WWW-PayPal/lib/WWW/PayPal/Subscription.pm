package WWW::PayPal::Subscription;

# ABSTRACT: PayPal Billing Subscription entity

use Moo;
use namespace::clean;

our $VERSION = '0.002';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => ( is => 'rw', required => 1 );


sub id         { $_[0]->data->{id} }
sub status     { $_[0]->data->{status} }
sub plan_id    { $_[0]->data->{plan_id} }
sub custom_id  { $_[0]->data->{custom_id} }
sub start_time { $_[0]->data->{start_time} }
sub create_time { $_[0]->data->{create_time} }
sub update_time { $_[0]->data->{update_time} }


sub _links { $_[0]->data->{links} || [] }

sub link_for {
    my ($self, $rel) = @_;
    for my $l (@{ $self->_links }) {
        return $l->{href} if $l->{rel} && $l->{rel} eq $rel;
    }
    return;
}


sub approve_url {
    my ($self) = @_;
    return $self->link_for('approve');
}


sub subscriber_email {
    $_[0]->data->{subscriber}{email_address};
}

sub subscriber_name {
    my ($self) = @_;
    my $n = $self->data->{subscriber}{name} or return;
    return join(' ', grep { defined && length } $n->{given_name}, $n->{surname});
}

sub subscriber_payer_id {
    $_[0]->data->{subscriber}{payer_id};
}


sub next_billing_time {
    $_[0]->data->{billing_info}{next_billing_time};
}

sub last_payment_amount {
    $_[0]->data->{billing_info}{last_payment}{amount}{value};
}

sub last_payment_currency {
    $_[0]->data->{billing_info}{last_payment}{amount}{currency_code};
}

sub cycle_executions {
    $_[0]->data->{billing_info}{cycle_executions};
}


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->subscriptions->get($self->id);
    $self->data($fresh->data);
    return $self;
}

sub suspend  { my $s = shift; $s->_client->subscriptions->suspend($s->id, @_);  $s->refresh }
sub activate { my $s = shift; $s->_client->subscriptions->activate($s->id, @_); $s->refresh }
sub cancel   { my $s = shift; $s->_client->subscriptions->cancel($s->id, @_);   $s->refresh }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Subscription - PayPal Billing Subscription entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $sub = $pp->subscriptions->create(plan_id => $plan_id, ...);

    print $sub->id;
    print $sub->status;            # APPROVAL_PENDING / ACTIVE / SUSPENDED / CANCELLED / EXPIRED
    print $sub->approve_url;       # redirect the buyer here

    # ... after approval ...
    $sub->refresh;
    print $sub->status;            # ACTIVE
    print $sub->subscriber_email;
    print $sub->subscriber_name;
    print $sub->next_billing_time;
    print $sub->last_payment_amount, ' ', $sub->last_payment_currency;

    $sub->suspend(reason => 'User paused');
    $sub->activate(reason => 'Resumed');
    $sub->cancel(reason  => 'User cancelled');

=head1 DESCRIPTION

Wrapper around a PayPal Billing Subscription JSON object. A subscription is
the per-user, recurring-payment binding between a buyer and a
L<plan|WWW::PayPal::Plan>. Once the buyer approves it at L</approve_url>,
PayPal auto-bills them on the plan's schedule.

=head2 data

Raw decoded JSON for the subscription.

=head2 id

Subscription ID (e.g. C<I-XXX...>).

=head2 status

C<APPROVAL_PENDING>, C<APPROVED>, C<ACTIVE>, C<SUSPENDED>, C<CANCELLED> or
C<EXPIRED>.

=head2 plan_id

ID of the billing plan backing this subscription.

=head2 custom_id

Merchant-supplied reference (e.g. your internal user/account ID).

=head2 start_time

=head2 create_time

=head2 update_time

=head2 link_for

    my $url = $sub->link_for('approve');

Looks up a HATEOAS link by C<rel>.

=head2 approve_url

URL the buyer must visit to approve the subscription. Only meaningful while
status is C<APPROVAL_PENDING>.

=head2 subscriber_email

=head2 subscriber_name

C<given_name> + C<surname>.

=head2 subscriber_payer_id

=head2 next_billing_time

ISO-8601 timestamp of PayPal's next billing attempt, e.g.
C<2026-05-15T10:00:00Z>.

=head2 last_payment_amount

String amount of the most recent successful payment.

=head2 last_payment_currency

Currency code of the most recent successful payment.

=head2 cycle_executions

Raw ArrayRef describing how many cycles have executed in each tenure
(C<TRIAL>, C<REGULAR>).

=head2 refresh

=head2 suspend

=head2 activate

=head2 cancel

    $sub->suspend(reason => 'holiday');
    $sub->activate(reason => 'back');
    $sub->cancel(reason  => 'user quit');

Lifecycle actions that also L</refresh> the local data afterwards.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::API::Subscriptions>

=item * L<WWW::PayPal::Plan>

=item * L<WWW::PayPal::Product>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-paypal/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
