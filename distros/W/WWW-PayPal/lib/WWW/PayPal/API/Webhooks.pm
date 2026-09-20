package WWW::PayPal::API::Webhooks;

# ABSTRACT: PayPal Webhooks API (v1) — management + signature verification

use Moo;
use Carp qw( croak );
use JSON::MaybeXS qw( encode_json );
use WWW::PayPal::Webhook;
use namespace::clean;

our $VERSION = '0.003';


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'notifications.verify-webhook-signature' => { method => 'POST',   path => '/v1/notifications/verify-webhook-signature' },
            'notifications.webhooks.create'          => { method => 'POST',   path => '/v1/notifications/webhooks' },
            'notifications.webhooks.list'            => { method => 'GET',    path => '/v1/notifications/webhooks' },
            'notifications.webhooks.get'             => { method => 'GET',    path => '/v1/notifications/webhooks/{id}' },
            'notifications.webhooks.delete'          => { method => 'DELETE', path => '/v1/notifications/webhooks/{id}' },
        };
    },
);

with 'WWW::PayPal::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::PayPal::Webhook->new(client => $self->client, data => $data);
}

sub verify {
    my ($self, %args) = @_;
    for my $k (qw( webhook_id raw_body transmission_id transmission_time transmission_sig cert_url auth_algo )) {
        croak $k.' required' unless defined $args{$k} && length $args{$k};
    }
    croak 'raw_body must be a byte string, not a reference'
        if ref $args{raw_body};

    my $raw_body = $args{raw_body};

    # Encode ONLY the metadata, then splice the raw event bytes in verbatim.
    # The event body must never pass through a JSON decode+encode round-trip —
    # that would reorder keys / re-whitespace and break the signature. This
    # produces a non-ref scalar body, which Role::HTTP::request sends as-is
    # (the ref branch would re-serialise it).
    my $meta = encode_json({
        auth_algo         => $args{auth_algo},
        cert_url          => $args{cert_url},
        transmission_id   => $args{transmission_id},
        transmission_sig  => $args{transmission_sig},
        transmission_time => $args{transmission_time},
        webhook_id        => $args{webhook_id},
    });
    $meta =~ s/\}\z/,"webhook_event":$raw_body}/;

    my $data = $self->call_operation('notifications.verify-webhook-signature', body => $meta);

    # Return a real boolean, never the raw status string: "FAILURE" is truthy
    # and a caller doing `if ($ok)` on it would grant access to a forged event.
    return ( ($data->{verification_status} // '') eq 'SUCCESS' ) ? 1 : 0;
}


sub create {
    my ($self, %args) = @_;
    croak 'url required' unless $args{url};
    croak 'event_types required (arrayref of event names)'
        unless $args{event_types} && ref $args{event_types} eq 'ARRAY' && @{ $args{event_types} };

    my %body = (
        url         => $args{url},
        event_types => [ map { ref $_ eq 'HASH' ? $_ : { name => $_ } } @{ $args{event_types} } ],
    );
    return $self->_wrap($self->call_operation('notifications.webhooks.create', body => \%body));
}


sub list {
    my ($self) = @_;
    my $data = $self->call_operation('notifications.webhooks.list');
    return [ map { $self->_wrap($_) } @{ $data->{webhooks} || [] } ];
}


sub get {
    my ($self, $id) = @_;
    croak 'webhook id required' unless $id;
    return $self->_wrap($self->call_operation('notifications.webhooks.get', path => { id => $id }));
}


sub delete {
    my ($self, $id) = @_;
    croak 'webhook id required' unless $id;
    # PayPal returns 204 No Content; Role::HTTP hands back undef. There is
    # nothing to wrap — just report success.
    $self->call_operation('notifications.webhooks.delete', path => { id => $id });
    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Webhooks - PayPal Webhooks API (v1) — management + signature verification

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    # One-time, per-environment setup: register the receiver
    my $webhook = $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [
            'CHECKOUT.ORDER.APPROVED',
            'PAYMENT.CAPTURE.COMPLETED',
            'BILLING.SUBSCRIPTION.ACTIVATED',
            'PAYMENT.SALE.COMPLETED',
        ],
        # or import symbols from WWW::PayPal::WebhookEvents
    );
    # store $webhook->id in per-environment config (sandbox != live)

    # In the receiver, for every incoming event:
    my $ok = $pp->webhooks->verify(
        webhook_id        => $config->{webhook_id},   # NEVER hard-code / default
        raw_body          => $raw_bytes,              # the untouched request body
        transmission_id   => $req->header('Paypal-Transmission-Id'),
        transmission_time => $req->header('Paypal-Transmission-Time'),
        transmission_sig  => $req->header('Paypal-Transmission-Sig'),
        cert_url          => $req->header('Paypal-Cert-Url'),
        auth_algo         => $req->header('Paypal-Auth-Algo'),
    );
    return unless $ok;   # forged / tampered — do not act on it

=head1 DESCRIPTION

Controller for PayPal's Webhooks API: register/list/delete webhook endpoint
subscriptions, and — the security-critical part — verify the signature of an
incoming webhook event via PayPal's
C<POST /v1/notifications/verify-webhook-signature> endpoint.

Verification is done through PayPal's endpoint rather than local certificate
chain validation: it keeps the operation table hand-maintained and adds no
crypto dependency, at the cost of one extra API round-trip per event.

=head2 Receiver discipline

An unverified receiver is a "grant everyone premium" endpoint. Whatever
framework you receive with:

=over 4

=item * B<Always L</verify> before acting> on an event. The payload alone is
not authentication.

=item * B<Capture the raw request body before anything parses it.> Verification
signs the exact bytes PayPal sent; a framework that decodes and re-serialises
JSON changes the bytes and the signature will never verify. See L</verify> for
how this module keeps those bytes intact.

=item * B<Dedupe on the event C<id>> in storage with a unique index before
doing any work — PayPal redelivers events, for up to ~3 days, until you answer
2xx.

=item * B<Answer 2xx fast and process asynchronously.> Slow handlers cause
retries, retries cause duplicates.

=item * B<Do not assume event ordering.> C<BILLING.SUBSCRIPTION.ACTIVATED> may
arrive after the first C<PAYMENT.SALE.COMPLETED>; handlers must be commutative
or re-fetch the object.

=back

=head2 verify

    my $ok = $pp->webhooks->verify(
        webhook_id        => $config_webhook_id,
        raw_body          => $raw_request_bytes,
        transmission_id   => $headers{'paypal-transmission-id'},
        transmission_time => $headers{'paypal-transmission-time'},
        transmission_sig  => $headers{'paypal-transmission-sig'},
        cert_url          => $headers{'paypal-cert-url'},
        auth_algo         => $headers{'paypal-auth-algo'},
    );

Verifies an incoming webhook event's signature against PayPal. All seven
arguments are B<required and named> (never positional) and each croaks if
missing or empty. In particular C<webhook_id> is B<never defaulted> — it is
per-environment, and a sandbox ID will not verify a live event or vice versa.

Returns a real boolean: C<1> when PayPal reports C<verification_status =>
SUCCESS>, C<0> otherwise. A forged or tampered event comes back as HTTP 200
with status C<FAILURE>, so this returns C<0> B<without croaking> — a false
result is the expected "reject it" path, not an error. Only a transport error
or a 4xx/5xx croaks (from L<WWW::PayPal::Role::HTTP>).

C<raw_body> must be the B<untouched bytes> of the request as PayPal sent them;
this method splices them into the verification payload verbatim rather than
decoding and re-encoding, so the signed bytes are preserved. Passing a decoded
structure (an ArrayRef/HashRef) is a reference and croaks; passing bytes that
you already round-tripped through a JSON parser will verify as C<FAILURE>.

=head2 create

    my $webhook = $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [ 'PAYMENT.CAPTURE.COMPLETED', 'CHECKOUT.ORDER.APPROVED' ],
    );

Registers a webhook endpoint. Each C<event_types> element may be a plain
event-name string (or a L<WWW::PayPal::WebhookEvents> constant), which this
method wraps into PayPal's required C<< { name => ... } >> shape for you, B<or>
an already-wrapped C<< { name => ... } >> HashRef as PayPal's own documentation
shows it — those pass through untouched, so the two forms may be mixed freely
in one list. Returns a L<WWW::PayPal::Webhook>.

=head2 list

    my $webhooks = $pp->webhooks->list;

Returns an ArrayRef of L<WWW::PayPal::Webhook> for every registered endpoint.

=head2 get

    my $webhook = $pp->webhooks->get($id);

Fetches a single webhook by ID. Returns a L<WWW::PayPal::Webhook>.

=head2 delete

    $pp->webhooks->delete($id);

Deletes a webhook endpoint. PayPal answers C<204 No Content>, so this returns a
plain true value rather than an entity.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::Webhook>

=item * L<WWW::PayPal::WebhookEvents>

=item * L<WWW::PayPal::Role::OpenAPI>

=item * L<https://developer.paypal.com/docs/api/webhooks/v1/>

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
