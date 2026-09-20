package WWW::PayPal::WebhookEvents;

# ABSTRACT: Curated PayPal webhook event-name constants

use strict;
use warnings;
use Exporter qw( import );

our $VERSION = '0.003';


use constant {
  CHECKOUT_ORDER_APPROVED             => 'CHECKOUT.ORDER.APPROVED',
  PAYMENT_CAPTURE_COMPLETED           => 'PAYMENT.CAPTURE.COMPLETED',
  PAYMENT_CAPTURE_DENIED              => 'PAYMENT.CAPTURE.DENIED',
  PAYMENT_CAPTURE_DECLINED            => 'PAYMENT.CAPTURE.DECLINED',
  PAYMENT_CAPTURE_REFUNDED            => 'PAYMENT.CAPTURE.REFUNDED',
  PAYMENT_CAPTURE_REVERSED            => 'PAYMENT.CAPTURE.REVERSED',
  BILLING_SUBSCRIPTION_ACTIVATED      => 'BILLING.SUBSCRIPTION.ACTIVATED',
  BILLING_SUBSCRIPTION_UPDATED        => 'BILLING.SUBSCRIPTION.UPDATED',
  BILLING_SUBSCRIPTION_SUSPENDED      => 'BILLING.SUBSCRIPTION.SUSPENDED',
  BILLING_SUBSCRIPTION_CANCELLED      => 'BILLING.SUBSCRIPTION.CANCELLED',
  BILLING_SUBSCRIPTION_EXPIRED        => 'BILLING.SUBSCRIPTION.EXPIRED',
  BILLING_SUBSCRIPTION_PAYMENT_FAILED => 'BILLING.SUBSCRIPTION.PAYMENT.FAILED',
  PAYMENT_SALE_COMPLETED              => 'PAYMENT.SALE.COMPLETED',
  CUSTOMER_DISPUTE_CREATED            => 'CUSTOMER.DISPUTE.CREATED',
};

our @EXPORT_OK = qw(
  CHECKOUT_ORDER_APPROVED
  PAYMENT_CAPTURE_COMPLETED
  PAYMENT_CAPTURE_DENIED
  PAYMENT_CAPTURE_DECLINED
  PAYMENT_CAPTURE_REFUNDED
  PAYMENT_CAPTURE_REVERSED
  BILLING_SUBSCRIPTION_ACTIVATED
  BILLING_SUBSCRIPTION_UPDATED
  BILLING_SUBSCRIPTION_SUSPENDED
  BILLING_SUBSCRIPTION_CANCELLED
  BILLING_SUBSCRIPTION_EXPIRED
  BILLING_SUBSCRIPTION_PAYMENT_FAILED
  PAYMENT_SALE_COMPLETED
  CUSTOMER_DISPUTE_CREATED
);

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::WebhookEvents - Curated PayPal webhook event-name constants

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WWW::PayPal::WebhookEvents qw( :all );

    my $webhook = $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [
            CHECKOUT_ORDER_APPROVED,
            PAYMENT_CAPTURE_COMPLETED,
            BILLING_SUBSCRIPTION_ACTIVATED,
            PAYMENT_SALE_COMPLETED,
        ],
    );

    # ...or import a single name:
    use WWW::PayPal::WebhookEvents qw( PAYMENT_CAPTURE_COMPLETED );

=head1 DESCRIPTION

Plain constant module (no Moo) exporting the PayPal webhook event names that
the two flows this distribution targets actually need: one-off purchases
(Orders v2 / capture) and recurring subscriptions (Billing v1), plus the
dispute event that must always reach a human. Each constant is the exact
event-type string PayPal sends and expects in a webhook subscription's
C<event_types>.

Constant names are the event strings with dots turned into underscores and
uppercased, so C<PAYMENT.CAPTURE.COMPLETED> becomes
L</PAYMENT_CAPTURE_COMPLETED>.

Import individual names, or the whole set with the C<:all> tag.

=head2 CHECKOUT_ORDER_APPROVED

C<CHECKOUT.ORDER.APPROVED> — buyer approved an order; safe to capture
server-side.

=head2 PAYMENT_CAPTURE_COMPLETED

C<PAYMENT.CAPTURE.COMPLETED> — money received. Grant the one-off entitlement
here, not in the browser return handler.

=head2 PAYMENT_CAPTURE_DENIED

C<PAYMENT.CAPTURE.DENIED> — a capture was denied (Payments v1). Revoke / never
grant.

=head2 PAYMENT_CAPTURE_DECLINED

C<PAYMENT.CAPTURE.DECLINED> — a capture was declined (Payments v2, the version
Orders v2 captures emit). Revoke / never grant.

=head2 PAYMENT_CAPTURE_REFUNDED

C<PAYMENT.CAPTURE.REFUNDED> — a capture was refunded (possibly from the PayPal
web UI, not your code).

=head2 PAYMENT_CAPTURE_REVERSED

C<PAYMENT.CAPTURE.REVERSED> — money taken back, e.g. a chargeback outcome.

=head2 BILLING_SUBSCRIPTION_ACTIVATED

C<BILLING.SUBSCRIPTION.ACTIVATED> — start the subscription entitlement.

=head2 BILLING_SUBSCRIPTION_UPDATED

C<BILLING.SUBSCRIPTION.UPDATED> — plan/quantity change went through.

=head2 BILLING_SUBSCRIPTION_SUSPENDED

C<BILLING.SUBSCRIPTION.SUSPENDED> — pause the entitlement. Check
C<failed_payments_count> before assuming the user paused voluntarily.

=head2 BILLING_SUBSCRIPTION_CANCELLED

C<BILLING.SUBSCRIPTION.CANCELLED> — terminal; end the entitlement.

=head2 BILLING_SUBSCRIPTION_EXPIRED

C<BILLING.SUBSCRIPTION.EXPIRED> — terminal; end the entitlement.

=head2 BILLING_SUBSCRIPTION_PAYMENT_FAILED

C<BILLING.SUBSCRIPTION.PAYMENT.FAILED> — dunning: warn the user, count attempts.

=head2 PAYMENT_SALE_COMPLETED

C<PAYMENT.SALE.COMPLETED> — a recurring payment was collected. This, not a
subscription event, is the renewal trigger.

=head2 CUSTOMER_DISPUTE_CREATED

C<CUSTOMER.DISPUTE.CREATED> — a human must look; freeze automated refunds for
that transaction.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::API::Webhooks>

=item * L<https://developer.paypal.com/api/rest/webhooks/event-names/>

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
