#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::PayPal;
use WWW::PayPal::API::Webhooks;
use WWW::PayPal::Webhook;
use WWW::PayPal::WebhookEvents qw( :all );

# Offline only: every call_operation is stubbed. Nothing reaches PayPal.

my $pp = WWW::PayPal->new(
    client_id => 'test',
    secret    => 'test',
    sandbox   => 1,
);

isa_ok $pp->webhooks, 'WWW::PayPal::API::Webhooks', 'webhooks controller';

# ---------------------------------------------------------------------------
# (a) operation lookup + path substitution
# ---------------------------------------------------------------------------
{
    my $wh = $pp->webhooks;
    my %expect = (
        'notifications.verify-webhook-signature' => [ 'POST',   '/v1/notifications/verify-webhook-signature' ],
        'notifications.webhooks.create'          => [ 'POST',   '/v1/notifications/webhooks' ],
        'notifications.webhooks.list'            => [ 'GET',    '/v1/notifications/webhooks' ],
        'notifications.webhooks.get'             => [ 'GET',    '/v1/notifications/webhooks/{id}' ],
        'notifications.webhooks.delete'          => [ 'DELETE', '/v1/notifications/webhooks/{id}' ],
    );
    for my $op_id (sort keys %expect) {
        my $op = $wh->get_operation($op_id);
        is $op->{method}, $expect{$op_id}[0], "$op_id method";
        is $op->{path},   $expect{$op_id}[1], "$op_id path";
    }

    is $wh->_resolve_path($wh->get_operation('notifications.webhooks.get')->{path}, { id => 'WH-123' }),
       '/v1/notifications/webhooks/WH-123', 'get path {id} substitution';
    is $wh->_resolve_path($wh->get_operation('notifications.webhooks.delete')->{path}, { id => 'WH-9' }),
       '/v1/notifications/webhooks/WH-9', 'delete path {id} substitution';

    eval { $wh->get_operation('notifications.nope') };
    like $@, qr/unknown operationId/, 'unknown op dies';
}

# ---------------------------------------------------------------------------
# (b) RAW-BODY INVARIANT: the event bytes must reach the wire verbatim,
#     never through a JSON decode+encode round-trip.
# ---------------------------------------------------------------------------
{
    # Deliberately awkward: leading/trailing whitespace, indentation, and a
    # key ordering (zzz before resource) that any re-serialisation would
    # normalise away. If the raw substring survives, no round-trip happened.
    my $raw_body = qq({\n  "id": "WH-EVT-1",\n  "event_type":    "PAYMENT.CAPTURE.COMPLETED",\n  "zzz": "keep me first",\n  "resource": { "amount": { "value": "9.99" } }\n}\n);

    my $sent_body;
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        my ($self, $op, %args) = @_;
        is $op, 'notifications.verify-webhook-signature', 'verify calls the verify op';
        $sent_body = $args{body};
        return { verification_status => 'SUCCESS' };
    };

    my $ok = $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => $raw_body,
        transmission_id   => 'tid-1',
        transmission_time => '2026-09-10T00:00:00Z',
        transmission_sig  => 'c2ln==',
        cert_url          => 'https://api.paypal.com/v1/notifications/certs/x',
        auth_algo         => 'SHA256withRSA',
    );

    ok !ref $sent_body,
        'body sent as a non-ref scalar (Role::HTTP passes it through verbatim)';
    ok index($sent_body, $raw_body) >= 0,
        'raw event bytes appear verbatim in the request body (no re-serialisation)';
    like $sent_body, qr/"webhook_event":/, 'webhook_event key spliced in';
    like $sent_body, qr/"webhook_id":"WH-CONFIG-1"/,
        'webhook_id taken from the caller, never defaulted';
    is $ok, 1, 'verify returns 1 on SUCCESS';
}

# ---------------------------------------------------------------------------
# (b2) ADVERSARIAL SPLICE REGRESSION (critical): raw_body carries s///
#      replacement metacharacters ($1, \1, \g{x}, $&) AND an internal "}"
#      that is not the final character. The current implementation is a
#      plain (non-/e) s/\}\z/,"webhook_event":$raw_body}/, which is safe: a
#      variable interpolated into a substitution replacement is inserted as
#      inert text, never re-parsed for backreferences. A refactor onto
#      s///e (raw_body's "$1"/"\1"/"$&" would be evaluated as the *real*
#      capture variables — empty here, since the pattern has no groups —
#      silently deleting them from the output), onto sprintf (a stray "%"
#      convention or double-escaping bug), or onto substr-based splicing
#      (anchoring on *a* "}" instead of the final one, or an off-by-one)
#      would each stop the raw bytes from appearing byte-for-byte in the
#      outgoing body. This test fails the moment that happens.
# ---------------------------------------------------------------------------
{
    my $raw_body = qq({"note":"\$1 \\1 \\g{x} back\\\\slash \$&","id":"x","z":"}"});

    # Fixture sanity: prove THIS test's own literal really carries the raw
    # metacharacters rather than something having been interpolated away by
    # accident. Every search term below is single-quoted (q(...)), so it can
    # never itself be interpolated — a match here proves the bytes are
    # genuinely present in $raw_body.
    ok index($raw_body, q($1))    >= 0, 'fixture sanity: literal $1 present in raw_body';
    ok index($raw_body, q(\1))    >= 0, 'fixture sanity: literal \1 present in raw_body';
    ok index($raw_body, q(\g{x})) >= 0, 'fixture sanity: literal \g{x} present in raw_body';
    ok index($raw_body, (chr(92) x 2).q(slash)) >= 0,
        'fixture sanity: literal double-backslash before "slash" present in raw_body';
    ok index($raw_body, q($&))    >= 0, 'fixture sanity: literal $& present in raw_body';
    ok index($raw_body, q(") . q(z) . q(") . q(:) . q(") . q(}) . q(") . q(})) >= 0,
        'fixture sanity: internal "}" (not the trailing one) present in raw_body';
    is length($raw_body), 54, 'fixture sanity: raw_body is exactly the intended 54 raw bytes';

    my $sent_body;
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        my ($self, $op, %args) = @_;
        $sent_body = $args{body};
        return { verification_status => 'SUCCESS' };
    };

    my $ok = $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => $raw_body,
        transmission_id   => 'tid-2',
        transmission_time => '2026-09-10T00:00:01Z',
        transmission_sig  => 'c2ln==',
        cert_url          => 'https://api.paypal.com/v1/notifications/certs/x',
        auth_algo         => 'SHA256withRSA',
    );

    ok !ref $sent_body, 'adversarial body: request body is still a non-ref scalar';
    ok index($sent_body, $raw_body) >= 0,
        'adversarial body: raw bytes appear byte-for-byte, unaltered, in the outgoing body';
    is $ok, 1, 'adversarial body: verify still resolves SUCCESS normally';
}

# ---------------------------------------------------------------------------
# (b3) Non-ASCII / multibyte raw bytes survive the splice verbatim. A refactor
#      that measures or slices by character count instead of byte count (a
#      substr-based splice, or one that runs under `use utf8` assumptions, or
#      one that decodes+re-encodes through JSON) could corrupt or shift a
#      multibyte UTF-8 sequence even while an all-ASCII fixture stays intact.
# ---------------------------------------------------------------------------
{
    # 'é' and '€' as raw UTF-8 byte sequences (0xC3 0xA9 and 0xE2 0x82 0xAC) —
    # exactly what a receiver reading the request body as bytes (not decoded
    # text) hands to verify().
    my $raw_body = "{\"note\":\"caf\xc3\xa9 \xe2\x82\xac\",\"id\":\"evt-utf8\"}";

    my $sent_body;
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        my ($self, $op, %args) = @_;
        $sent_body = $args{body};
        return { verification_status => 'SUCCESS' };
    };

    $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => $raw_body,
        transmission_id   => 't', transmission_time => 'x',
        transmission_sig  => 's', cert_url => 'u', auth_algo => 'a',
    );

    ok !ref $sent_body, 'non-ASCII body: request body is still a non-ref scalar';
    ok index($sent_body, $raw_body) >= 0,
        'non-ASCII body: raw UTF-8 bytes survive the splice verbatim (byte-based, not character-based)';
}

# ---------------------------------------------------------------------------
# (c) verify returns a real boolean: 1 for SUCCESS, 0 (false) for FAILURE.
#     A forged event is HTTP 200 + FAILURE and must never be truthy.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        return { verification_status => 'FAILURE' };
    };
    my $r = $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => '{"id":"evt"}',
        transmission_id   => 't', transmission_time => 'x',
        transmission_sig  => 's', cert_url => 'u', auth_algo => 'a',
    );
    is $r, 0, 'verify returns 0 on FAILURE';
    ok !$r, 'FAILURE result is falsey (forged signature never grants access)';
}

# ---------------------------------------------------------------------------
# (c2) verify returns exactly 0 when verification_status is missing or undef
#      in PayPal's response — the fail-closed `// ''` branch. Only the
#      SUCCESS/FAILURE string values were exercised above; if a refactor
#      dropped the `// ''` and compared $data->{verification_status} eq
#      'SUCCESS' directly, an undef value would warn under `use warnings`
#      and could — depending on how the comparison is restructured — stop
#      being reliably falsey. This pins the current fail-closed value exactly.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub { return {} };
    my $r = $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => '{"id":"evt"}',
        transmission_id   => 't', transmission_time => 'x',
        transmission_sig  => 's', cert_url => 'u', auth_algo => 'a',
    );
    is $r, 0, 'verify returns exactly 0 when verification_status key is absent from the response';
}
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub { return undef };
    my $r = $pp->webhooks->verify(
        webhook_id        => 'WH-CONFIG-1',
        raw_body          => '{"id":"evt"}',
        transmission_id   => 't', transmission_time => 'x',
        transmission_sig  => 's', cert_url => 'u', auth_algo => 'a',
    );
    is $r, 0, 'verify returns exactly 0 when call_operation itself returns undef';
}

# missing / empty required args croak (spot-check two of the seven)
{
    eval { $pp->webhooks->verify( raw_body => '{}' ) };
    like $@, qr/webhook_id required/, 'verify croaks without webhook_id';

    eval {
        $pp->webhooks->verify(
            webhook_id => 'WH', raw_body => '',
            transmission_id => 't', transmission_time => 'x',
            transmission_sig => 's', cert_url => 'u', auth_algo => 'a',
        );
    };
    like $@, qr/raw_body required/, 'verify croaks on empty raw_body';

    eval {
        $pp->webhooks->verify(
            webhook_id => 'WH', raw_body => { id => 'evt' },
            transmission_id => 't', transmission_time => 'x',
            transmission_sig => 's', cert_url => 'u', auth_algo => 'a',
        );
    };
    like $@, qr/raw_body must be a byte string/,
        'verify croaks when raw_body is a decoded reference, not bytes';
}

# ---------------------------------------------------------------------------
# (d) create wraps bare event names into PayPal's {name=>...} shape.
# ---------------------------------------------------------------------------
{
    my $sent;
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        my ($self, $op, %args) = @_;
        $sent = { op => $op, %args };
        return {
            id          => 'WH-NEW',
            url         => $args{body}{url},
            event_types => $args{body}{event_types},
        };
    };

    my $w = $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [ CHECKOUT_ORDER_APPROVED, PAYMENT_CAPTURE_COMPLETED ],
    );

    is $sent->{op}, 'notifications.webhooks.create', 'create op';
    is $sent->{body}{url}, 'https://example.com/paypal/webhook', 'create url';
    is_deeply $sent->{body}{event_types},
        [ { name => 'CHECKOUT.ORDER.APPROVED' }, { name => 'PAYMENT.CAPTURE.COMPLETED' } ],
        'bare event names wrapped as [{name=>...}]';
    isa_ok $w, 'WWW::PayPal::Webhook', 'create returns entity';
    is $w->id, 'WH-NEW', 'created webhook id';

    # R1: an already-wrapped { name => ... } hashref (PayPal's own doc form)
    # passes through untouched and may be mixed with bare names — never
    # double-wrapped into { name => { name => ... } }.
    $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [ CHECKOUT_ORDER_APPROVED, { name => 'PAYMENT.CAPTURE.COMPLETED' } ],
    );
    is_deeply $sent->{body}{event_types},
        [ { name => 'CHECKOUT.ORDER.APPROVED' }, { name => 'PAYMENT.CAPTURE.COMPLETED' } ],
        'bare and pre-wrapped {name=>...} forms mix; no double-wrapping';

    eval { $pp->webhooks->create( url => 'https://x' ) };
    like $@, qr/event_types required/, 'create without event_types dies';
}

# ---------------------------------------------------------------------------
# list wraps each element; delete tolerates 204 (undef) and returns true.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub {
        return { webhooks => [
            { id => 'WH-1', url => 'https://a' },
            { id => 'WH-2', url => 'https://b' },
        ] };
    };
    my $list = $pp->webhooks->list;
    is ref($list), 'ARRAY', 'list returns arrayref';
    is scalar(@$list), 2, 'two webhooks';
    isa_ok $list->[0], 'WWW::PayPal::Webhook', 'list element wrapped';
    is $list->[1]->id, 'WH-2', 'second webhook id';
}
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Webhooks::call_operation = sub { return undef };  # 204 No Content
    my $r = $pp->webhooks->delete('WH-1');
    ok $r, 'delete returns true even though 204 gives undef (not wrapped)';

    eval { $pp->webhooks->delete };
    like $@, qr/webhook id required/, 'delete without id dies';
}

# ---------------------------------------------------------------------------
# (e) Webhook entity parsing from a sample payload.
# ---------------------------------------------------------------------------
{
    my $w = WWW::PayPal::Webhook->new(client => $pp, data => {
        id          => '1JE4291016473214C',
        url         => 'https://example.com/paypal/webhook',
        event_types => [
            { name => 'PAYMENT.CAPTURE.COMPLETED' },
            { name => 'BILLING.SUBSCRIPTION.ACTIVATED' },
        ],
    });
    is $w->id,  '1JE4291016473214C',                 'webhook entity id';
    is $w->url, 'https://example.com/paypal/webhook', 'webhook entity url';
    is_deeply [ $w->event_names ],
        [ 'PAYMENT.CAPTURE.COMPLETED', 'BILLING.SUBSCRIPTION.ACTIVATED' ],
        'event_names flattened from event_types';

    my $empty = WWW::PayPal::Webhook->new(client => $pp, data => { id => 'X' });
    is_deeply [ $empty->event_names ], [], 'event_names empty when no event_types';
}

# ---------------------------------------------------------------------------
# WebhookEvents constants carry the exact PayPal strings.
# ---------------------------------------------------------------------------
{
    is CHECKOUT_ORDER_APPROVED,    'CHECKOUT.ORDER.APPROVED',   'constant value CHECKOUT_ORDER_APPROVED';
    is PAYMENT_CAPTURE_COMPLETED,  'PAYMENT.CAPTURE.COMPLETED', 'constant value PAYMENT_CAPTURE_COMPLETED';
    is PAYMENT_CAPTURE_DENIED,     'PAYMENT.CAPTURE.DENIED',    'constant value PAYMENT_CAPTURE_DENIED (v1)';
    is PAYMENT_CAPTURE_DECLINED,   'PAYMENT.CAPTURE.DECLINED',  'constant value PAYMENT_CAPTURE_DECLINED (v2)';
    is PAYMENT_SALE_COMPLETED,     'PAYMENT.SALE.COMPLETED',    'constant value PAYMENT_SALE_COMPLETED';
    is CUSTOMER_DISPUTE_CREATED,   'CUSTOMER.DISPUTE.CREATED',  'constant value CUSTOMER_DISPUTE_CREATED';
}

done_testing;
