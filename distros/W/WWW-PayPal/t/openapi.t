#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::PayPal;
use WWW::PayPal::Order;
use WWW::PayPal::Subscription;

my $pp = WWW::PayPal->new(
    client_id => 'test',
    secret    => 'test',
    sandbox   => 1,
);

is $pp->base_url, 'https://api-m.sandbox.paypal.com', 'sandbox base_url';

my $orders = $pp->orders;
my $op = $orders->get_operation('orders.capture');
is $op->{method}, 'POST',                          'capture method';
is $op->{path},   '/v2/checkout/orders/{id}/capture', 'capture path';

is $orders->_resolve_path($op->{path}, { id => 'ABC' }),
   '/v2/checkout/orders/ABC/capture', 'path param substitution';

eval { $orders->_resolve_path('/a/{missing}', {}) };
like $@, qr/missing path parameter/, 'missing param dies';

eval { $orders->get_operation('does.not.exist') };
like $@, qr/unknown operationId/, 'unknown op dies';

# Entity parsing of a realistic captured order payload
my $order = WWW::PayPal::Order->new(client => $pp, data => {
    id     => '5O190127TN364715T',
    status => 'COMPLETED',
    intent => 'CAPTURE',
    payer  => {
        email_address => 'buyer@example.com',
        payer_id      => 'QYR5Z8XDVJNXQ',
        name          => { given_name => 'John', surname => 'Doe' },
    },
    purchase_units => [{
        amount => { currency_code => 'EUR', value => '42.00' },
        payments => { captures => [{
            id     => '3C679366HH908993F',
            status => 'COMPLETED',
            amount => { currency_code => 'EUR', value => '42.00' },
            seller_receivable_breakdown => {
                paypal_fee => { currency_code => 'EUR', value => '1.55' },
            },
        }] },
    }],
    links => [
        { rel => 'self', href => 'https://api/...' },
        { rel => 'payer-action', href => 'https://paypal.com/approve/XYZ' },
    ],
});

is $order->id,          '5O190127TN364715T',     'order id';
is $order->status,      'COMPLETED',             'order status';
is $order->payer_email, 'buyer@example.com',     'payer email';
is $order->payer_name,  'John Doe',              'payer name';
is $order->capture_id,  '3C679366HH908993F',     'capture id';
is $order->fee_in_cent, 155,                     'fee in cent';
is $order->total,       '42.00',                 'total';
is $order->currency,    'EUR',                   'currency';
is $order->approve_url, 'https://paypal.com/approve/XYZ',
    'approve url from payer-action link';

# --- Subscriptions ---

my $subs = $pp->subscriptions;
my $sop = $subs->get_operation('billing.subscriptions.cancel');
is $sop->{method}, 'POST', 'sub cancel method';
is $sop->{path},   '/v1/billing/subscriptions/{id}/cancel', 'sub cancel path';

is $pp->plans->get_operation('billing.plans.activate')->{path},
   '/v1/billing/plans/{id}/activate', 'plan activate path';

is $pp->products->get_operation('catalogs.products.create')->{path},
   '/v1/catalogs/products', 'product create path';

my $sub = WWW::PayPal::Subscription->new(client => $pp, data => {
    id         => 'I-BW452GLLEP1G',
    status     => 'ACTIVE',
    plan_id    => 'P-5ML4271244454362WXNWU5NQ',
    start_time => '2026-01-01T00:00:00Z',
    subscriber => {
        email_address => 'sub@example.com',
        name          => { given_name => 'Alice', surname => 'Wonder' },
    },
    billing_info => {
        next_billing_time => '2026-02-01T00:00:00Z',
        last_payment      => { amount => { currency_code => 'EUR', value => '9.99' } },
    },
    links => [
        { rel => 'approve', href => 'https://paypal.com/subscribe/XYZ' },
        { rel => 'self',    href => 'https://api/...' },
    ],
});

is $sub->id,                     'I-BW452GLLEP1G',       'sub id';
is $sub->status,                 'ACTIVE',                'sub status';
is $sub->approve_url,            'https://paypal.com/subscribe/XYZ',
    'sub approve url';
is $sub->subscriber_email,       'sub@example.com',       'sub email';
is $sub->subscriber_name,        'Alice Wonder',          'sub name';
is $sub->next_billing_time,      '2026-02-01T00:00:00Z',  'next billing';
is $sub->last_payment_amount,    '9.99',                  'last payment amount';
is $sub->last_payment_currency,  'EUR',                   'last payment currency';

# create_monthly plan body shape
my $plan_api = $pp->plans;
# Stub call_operation to capture the body it would send.
my $captured;
{
    no warnings 'redefine';
    local *WWW::PayPal::API::Plans::call_operation = sub {
        my ($self, $op, %args) = @_;
        $captured = { op => $op, %args };
        return {
            id => 'P-STUB',
            product_id => $args{body}{product_id},
            name => $args{body}{name},
            status => 'CREATED',
            billing_cycles => $args{body}{billing_cycles},
        };
    };

    my $p = $plan_api->create_monthly(
        product_id => 'PROD-TEST',
        name       => 'test',
        price      => '9.99',
        currency   => 'EUR',
        trial_days => 7,
    );

    is $captured->{op}, 'billing.plans.create', 'plan create op';
    my $cycles = $captured->{body}{billing_cycles};
    is scalar(@$cycles), 2, 'trial + regular cycles';
    is $cycles->[0]{tenure_type},             'TRIAL',      'first cycle is trial';
    is $cycles->[0]{frequency}{interval_unit}, 'DAY',       'trial unit days';
    is $cycles->[0]{frequency}{interval_count}, 7,          'trial length';
    is $cycles->[1]{tenure_type},             'REGULAR',    'second cycle regular';
    is $cycles->[1]{frequency}{interval_unit}, 'MONTH',     'regular unit months';
    is $cycles->[1]{pricing_scheme}{fixed_price}{value}, '9.99',
        'regular price';
    is $p->id, 'P-STUB', 'wrapped plan id';
}

# --- checkout() convenience builder ---
{
    my $captured_body;
    no warnings 'redefine';
    local *WWW::PayPal::API::Orders::call_operation = sub {
        my ($self, $op, %args) = @_;
        $captured_body = $args{body};
        return {
            id     => 'ORDER-STUB',
            status => 'CREATED',
            intent => $args{body}{intent},
            links  => [{ rel => 'payer-action', href => 'https://pp/ap' }],
        };
    };

    my $o = $pp->orders->checkout(
        amount      => '9.99',
        currency    => 'EUR',
        return_url  => 'https://x/r',
        cancel_url  => 'https://x/c',
        brand_name  => 'Amiga Event',
        locale      => 'de-DE',
        invoice_id  => 'INV-1',
        custom_id   => 'user-42',
        description => 'Ticket',
        items => [
            { name => 'Ticket', quantity => 2, unit_amount => '4.00', sku => 'T' },
        ],
    );

    is $captured_body->{intent}, 'CAPTURE', 'default intent capture';
    is $captured_body->{purchase_units}[0]{amount}{value}, '9.99', 'pu amount';
    is $captured_body->{purchase_units}[0]{amount}{currency_code}, 'EUR', 'pu ccy';
    is $captured_body->{purchase_units}[0]{amount}{breakdown}{item_total}{value},
        '8.00', 'item_total breakdown auto-filled';
    is $captured_body->{purchase_units}[0]{items}[0]{name}, 'Ticket', 'item name';
    is $captured_body->{purchase_units}[0]{items}[0]{quantity}, '2', 'item qty';
    is $captured_body->{purchase_units}[0]{invoice_id},  'INV-1',   'invoice_id';
    is $captured_body->{purchase_units}[0]{custom_id},   'user-42', 'custom_id';
    is $captured_body->{application_context}{brand_name},  'Amiga Event', 'brand';
    is $captured_body->{application_context}{locale},      'de-DE',       'locale';
    is $captured_body->{application_context}{return_url},  'https://x/r', 'return';
    is $captured_body->{application_context}{user_action}, 'PAY_NOW',     'user_action';
    is $o->id, 'ORDER-STUB', 'wrapped order id';

    eval { $pp->orders->checkout(currency => 'EUR', return_url => 'x', cancel_url => 'x') };
    like $@, qr/amount required/, 'amount missing dies';
}

# --- js_sdk_url / js_sdk_script_tag ---
{
    my $url = $pp->js_sdk_url(currency => 'EUR', intent => 'capture');
    like $url, qr{^https://www\.paypal\.com/sdk/js\?}, 'sdk url base';
    like $url, qr/client-id=test/,  'sdk client-id';
    like $url, qr/currency=EUR/,    'sdk currency';
    like $url, qr/intent=capture/,  'sdk intent lower';
    like $url, qr/components=buttons/, 'sdk default components';

    my $sub_url = $pp->js_sdk_url(intent => 'subscription', vault => 1);
    like $sub_url, qr/intent=subscription/, 'sdk sub intent';
    like $sub_url, qr/vault=true/,          'sdk vault';

    my $df = $pp->js_sdk_url(
        currency        => 'EUR',
        disable_funding => ['credit', 'card'],
    );
    like $df, qr/disable-funding=credit%2Ccard/, 'disable_funding joined + escaped';

    my $tag = $pp->js_sdk_script_tag(currency => 'EUR');
    like $tag, qr{^<script src="https://www\.paypal\.com/sdk/js\?[^"]+"></script>$},
        'script tag shape';
    like $tag, qr/&amp;/, 'ampersands escaped';
    unlike $tag, qr/&(?!amp;|lt;|gt;|quot;)/, 'no raw ampersands';
}

done_testing;
