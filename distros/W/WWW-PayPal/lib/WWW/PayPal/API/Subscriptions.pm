package WWW::PayPal::API::Subscriptions;

# ABSTRACT: PayPal Billing Subscriptions API (v1)

use Moo;
use Carp qw(croak);
use WWW::PayPal::Subscription;
use namespace::clean;

our $VERSION = '0.002';


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'billing.subscriptions.create'       => { method => 'POST',  path => '/v1/billing/subscriptions' },
            'billing.subscriptions.get'          => { method => 'GET',   path => '/v1/billing/subscriptions/{id}' },
            'billing.subscriptions.patch'        => { method => 'PATCH', path => '/v1/billing/subscriptions/{id}' },
            'billing.subscriptions.revise'       => { method => 'POST',  path => '/v1/billing/subscriptions/{id}/revise' },
            'billing.subscriptions.suspend'      => { method => 'POST',  path => '/v1/billing/subscriptions/{id}/suspend' },
            'billing.subscriptions.activate'     => { method => 'POST',  path => '/v1/billing/subscriptions/{id}/activate' },
            'billing.subscriptions.cancel'       => { method => 'POST',  path => '/v1/billing/subscriptions/{id}/cancel' },
            'billing.subscriptions.capture'      => { method => 'POST',  path => '/v1/billing/subscriptions/{id}/capture' },
            'billing.subscriptions.transactions' => { method => 'GET',   path => '/v1/billing/subscriptions/{id}/transactions' },
        };
    },
);

with 'WWW::PayPal::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::PayPal::Subscription->new(client => $self->client, data => $data);
}

sub create {
    my ($self, %args) = @_;
    croak 'plan_id required' unless $args{plan_id};

    my %body = ( plan_id => $args{plan_id} );
    $body{subscriber}    = $args{subscriber}    if $args{subscriber};
    $body{quantity}      = $args{quantity}      if defined $args{quantity};
    $body{custom_id}     = $args{custom_id}     if defined $args{custom_id};
    $body{start_time}    = $args{start_time}    if defined $args{start_time};
    $body{shipping_amount} = $args{shipping_amount} if $args{shipping_amount};

    my %ctx;
    $ctx{return_url}  = $args{return_url}  if $args{return_url};
    $ctx{cancel_url}  = $args{cancel_url}  if $args{cancel_url};
    $ctx{brand_name}  = $args{brand_name}  if $args{brand_name};
    $ctx{locale}      = $args{locale}      if $args{locale};
    $ctx{user_action} = $args{user_action} // 'SUBSCRIBE_NOW';
    $ctx{shipping_preference} = $args{shipping_preference}
        if $args{shipping_preference};
    $body{application_context} = \%ctx if %ctx;

    my $data = $self->call_operation('billing.subscriptions.create', body => \%body);
    return $self->_wrap($data);
}


sub get {
    my ($self, $id) = @_;
    croak 'subscription id required' unless $id;
    return $self->_wrap($self->call_operation('billing.subscriptions.get', path => { id => $id }));
}


sub _action_with_reason {
    my ($self, $op, $id, %args) = @_;
    croak 'subscription id required' unless $id;
    my $reason = $args{reason} // 'not specified';
    return $self->call_operation($op,
        path => { id => $id },
        body => { reason => $reason },
    );
}

sub suspend  { my $s = shift; $s->_action_with_reason('billing.subscriptions.suspend',  @_) }
sub activate { my $s = shift; $s->_action_with_reason('billing.subscriptions.activate', @_) }
sub cancel   { my $s = shift; $s->_action_with_reason('billing.subscriptions.cancel',   @_) }


sub capture {
    my ($self, $id, %args) = @_;
    croak 'subscription id required' unless $id;
    croak 'amount required'          unless $args{amount};
    my $body = {
        note        => $args{note} // 'Outstanding balance',
        capture_type => $args{capture_type} // 'OUTSTANDING_BALANCE',
        amount      => $args{amount},
    };
    return $self->call_operation('billing.subscriptions.capture',
        path => { id => $id },
        body => $body,
    );
}


sub transactions {
    my ($self, $id, %args) = @_;
    croak 'subscription id required' unless $id;
    croak 'start_time required'      unless $args{start_time};
    croak 'end_time required'        unless $args{end_time};
    return $self->call_operation('billing.subscriptions.transactions',
        path  => { id => $id },
        query => {
            start_time => $args{start_time},
            end_time   => $args{end_time},
        },
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Subscriptions - PayPal Billing Subscriptions API (v1)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Per-user subscription
    my $sub = $pp->subscriptions->create(
        plan_id    => $plan->id,
        return_url => 'https://example.com/paypal/sub/return',
        cancel_url => 'https://example.com/paypal/sub/cancel',
        subscriber => {                           # optional
            email_address => 'buyer@example.com',
        },
    );

    my $approve_url = $sub->approve_url;          # redirect the buyer here

    # ... after approval ...
    my $same = $pp->subscriptions->get($sub->id);
    print $same->status;                          # ACTIVE

    # Lifecycle
    $pp->subscriptions->suspend($sub->id, reason => 'User paused');
    $pp->subscriptions->activate($sub->id, reason => 'Resumed');
    $pp->subscriptions->cancel($sub->id, reason => 'User cancelled');

=head1 DESCRIPTION

Controller for PayPal's Billing Subscriptions API — the per-user,
recurring-payment side of the subscription flow. A subscription references a
L<plan|WWW::PayPal::API::Plans> (which in turn references a
L<product|WWW::PayPal::API::Products>).

After the buyer approves the subscription at L</approve_url>, PayPal will
automatically bill them on the plan's schedule (e.g. monthly). No per-cycle
server action is needed — listen for webhooks
(C<BILLING.SUBSCRIPTION.*>, C<PAYMENT.SALE.COMPLETED>) if you want to react
to charges.

=head2 create

    my $sub = $pp->subscriptions->create(
        plan_id    => $plan_id,
        return_url => '...',
        cancel_url => '...',
        subscriber => { email_address => '...' },   # optional
        custom_id  => 'user-42',                    # optional merchant ref
    );

Creates a subscription and returns a L<WWW::PayPal::Subscription>. The buyer
must be redirected to L<< approve_url|WWW::PayPal::Subscription/approve_url >>
before PayPal starts billing.

=head2 get

    my $sub = $pp->subscriptions->get($id);

=head2 suspend

=head2 activate

=head2 cancel

    $pp->subscriptions->suspend($id, reason => 'User paused');
    $pp->subscriptions->activate($id, reason => 'Resumed');
    $pp->subscriptions->cancel($id, reason => 'User cancelled');

Lifecycle transitions. C<reason> is required by PayPal but defaults to
C<'not specified'> if you don't pass one.

=head2 capture

    $pp->subscriptions->capture($id,
        amount => { currency_code => 'EUR', value => '10.00' },
        note   => 'Reason shown to payer',
    );

Captures an outstanding balance on a subscription (e.g. after failed auto-bill).

=head2 transactions

    my $txs = $pp->subscriptions->transactions($id,
        start_time => '2026-01-01T00:00:00Z',
        end_time   => '2026-12-31T23:59:59Z',
    );

Returns the raw transactions list for a subscription in the given time window.

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
