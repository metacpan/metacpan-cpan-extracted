package WWW::PayPal;

# ABSTRACT: Perl client for the PayPal REST API

use Moo;
use Carp qw(croak);
use WWW::PayPal::API::Orders;
use WWW::PayPal::API::Payments;
use WWW::PayPal::API::Products;
use WWW::PayPal::API::Plans;
use WWW::PayPal::API::Subscriptions;
use namespace::clean;

our $VERSION = '0.002';


has client_id => (
    is      => 'ro',
    default => sub { $ENV{PAYPAL_CLIENT_ID} },
);


has secret => (
    is      => 'ro',
    default => sub { $ENV{PAYPAL_SECRET} },
);


has sandbox => (
    is      => 'ro',
    default => sub { $ENV{PAYPAL_SANDBOX} ? 1 : 0 },
);


has base_url => (
    is      => 'lazy',
    builder => sub {
        $_[0]->sandbox
            ? 'https://api-m.sandbox.paypal.com'
            : 'https://api-m.paypal.com';
    },
);


with 'WWW::PayPal::Role::HTTP';

has orders => (
    is      => 'lazy',
    builder => sub { WWW::PayPal::API::Orders->new(client => $_[0]) },
);


has payments => (
    is      => 'lazy',
    builder => sub { WWW::PayPal::API::Payments->new(client => $_[0]) },
);


has products => (
    is      => 'lazy',
    builder => sub { WWW::PayPal::API::Products->new(client => $_[0]) },
);


has plans => (
    is      => 'lazy',
    builder => sub { WWW::PayPal::API::Plans->new(client => $_[0]) },
);


has subscriptions => (
    is      => 'lazy',
    builder => sub { WWW::PayPal::API::Subscriptions->new(client => $_[0]) },
);


sub js_sdk_url {
    my ($self, %args) = @_;
    croak 'client_id required' unless $self->client_id;

    my %p = (
        'client-id' => $self->client_id,
        intent      => lc($args{intent} // 'capture'),
    );
    $p{currency}     = uc $args{currency}     if $args{currency};
    $p{locale}       = $args{locale}          if $args{locale};
    $p{'disable-funding'} = _join_list($args{disable_funding}) if $args{disable_funding};
    $p{'enable-funding'}  = _join_list($args{enable_funding})  if $args{enable_funding};
    $p{components}   = _join_list($args{components} // ['buttons']);
    $p{vault}        = 'true' if $args{vault};
    $p{'merchant-id'}    = $args{merchant_id}    if $args{merchant_id};
    $p{'buyer-country'}  = $args{buyer_country}  if $args{buyer_country} && $self->sandbox;
    $p{debug}        = 'true' if $args{debug};

    # Extra opaque params (e.g. data-partner-attribution-id is an HTML attr,
    # not a URL param, so we don't mix those in).
    if (my $extra = $args{params}) {
        $p{$_} = $extra->{$_} for keys %$extra;
    }

    my $qs = join('&',
        map { _uri_escape($_) . '=' . _uri_escape($p{$_}) }
        sort grep { defined $p{$_} } keys %p
    );
    return 'https://www.paypal.com/sdk/js?' . $qs;
}


sub js_sdk_script_tag {
    my ($self, %args) = @_;
    my $url = $self->js_sdk_url(%args);
    return '<script src="' . _html_escape($url) . '"></script>';
}

sub _join_list {
    my ($v) = @_;
    return ref $v eq 'ARRAY' ? join(',', @$v) : $v;
}

sub _uri_escape {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $s;
}

sub _html_escape {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal - Perl client for the PayPal REST API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::PayPal;

    my $pp = WWW::PayPal->new(
        client_id => $ENV{PAYPAL_CLIENT_ID},
        secret    => $ENV{PAYPAL_SECRET},
        sandbox   => 1,                    # default: 0 (live)
    );

    # Create an order — one-liner Express Checkout replacement
    my $order = $pp->orders->checkout(
        amount     => '42.00',
        currency   => 'EUR',
        return_url => 'https://example.com/paypal/return',
        cancel_url => 'https://example.com/paypal/cancel',
        brand_name => 'My Shop',
    );

    # Redirect the buyer here:
    my $approve_url = $order->approve_url;

    # After the buyer approves, capture the payment
    # (replaces GetExpressCheckoutDetails + DoExpressCheckoutPayment)
    my $captured = $pp->orders->capture($order->id);

    print $captured->payer_email, "\n";
    print $captured->fee_in_cent, "\n";

    # Refund a capture
    $pp->payments->refund($captured->capture_id,
        amount => { currency_code => 'EUR', value => '10.00' });

    # --- Recurring subscriptions ---

    # One-time merchant setup: product + plan (do this at deploy time)
    my $product = $pp->products->create(
        name => 'VIP membership', type => 'SERVICE', category => 'SOFTWARE',
    );
    my $plan = $pp->plans->create_monthly(
        product_id => $product->id,
        name       => 'VIP monthly',
        price      => '9.99',
        currency   => 'EUR',
    );

    # Per-user: create a subscription, redirect the buyer
    my $sub = $pp->subscriptions->create(
        plan_id    => $plan->id,
        return_url => 'https://example.com/paypal/sub/return',
        cancel_url => 'https://example.com/paypal/sub/cancel',
    );
    my $approve_url = $sub->approve_url;

    # Later: lifecycle
    $sub->refresh;
    $sub->suspend(reason => 'user paused');
    $sub->activate(reason => 'resumed');
    $sub->cancel(reason   => 'user quit');

=head1 DESCRIPTION

L<WWW::PayPal> wraps PayPal's REST API. The initial release covers the
Checkout / Orders v2 flow (one-off product sales, replacing the legacy NVP
ExpressCheckout dance) and the Billing Subscriptions v1 flow (recurring
monthly/yearly payments).

Operation dispatch uses cached OpenAPI operation tables (see
L<WWW::PayPal::Role::OpenAPI>), so no spec parsing happens at runtime.

=head2 client_id

PayPal REST app client ID. Defaults to the C<PAYPAL_CLIENT_ID> environment
variable.

=head2 secret

PayPal REST app secret. Defaults to the C<PAYPAL_SECRET> environment variable.

=head2 sandbox

When true, all requests go to C<api-m.sandbox.paypal.com>. Defaults to the
C<PAYPAL_SANDBOX> environment variable.

=head2 base_url

API base URL. Derived from L</sandbox> by default.

=head2 orders

Returns a L<WWW::PayPal::API::Orders> controller for the Checkout / Orders v2
API.

=head2 payments

Returns a L<WWW::PayPal::API::Payments> controller for captures, refunds and
authorizations.

=head2 products

Returns a L<WWW::PayPal::API::Products> controller for catalog products (the
abstract "what you're selling", referenced by plans).

=head2 plans

Returns a L<WWW::PayPal::API::Plans> controller for billing plans (the
recurring-cycle definitions that subscriptions reference).

=head2 subscriptions

Returns a L<WWW::PayPal::API::Subscriptions> controller for creating and
managing per-user recurring subscriptions.

=head2 js_sdk_url

    my $url = $pp->js_sdk_url(
        currency => 'EUR',
        intent   => 'capture',           # or 'authorize' / 'subscription'
        # optional:
        locale          => 'de_DE',
        components      => ['buttons'],  # or 'buttons,funding-eligibility'
        disable_funding => ['credit', 'card'],
        vault           => 1,            # required for subscriptions
        merchant_id     => '...',        # multi-seller / partner flows
        buyer_country   => 'DE',         # sandbox only
        debug           => 1,
    );

Builds the PayPal JS SDK script URL with the given parameters, using this
client's C<client_id>. For subscriptions, pass C<< intent => 'subscription' >>
and C<< vault => 1 >>.

=head2 js_sdk_script_tag

    my $html = $pp->js_sdk_script_tag(currency => 'EUR');
    # -> <script src="https://www.paypal.com/sdk/js?client-id=...&amp;currency=EUR&amp;..."></script>

Returns a ready-to-render HTML C<< <script> >> tag for the JS SDK, HTML-
escaped. Use this in your Catalyst / Mojolicious / whatever template to drop
the SDK onto the page. All arguments are forwarded to L</js_sdk_url>.

Typical integration (server-side order creation, client-side approval):

    # in your template
    [% pp.js_sdk_script_tag(currency => 'EUR') %]
    <div id="paypal-button"></div>
    <script>
    paypal.Buttons({
      createOrder: function() {
        return fetch('/paypal/create', {method:'POST'})
          .then(function(r){ return r.json() })
          .then(function(d){ return d.id });
      },
      onApprove: function(data) {
        return fetch('/paypal/capture/' + data.orderID, {method:'POST'})
          .then(function(r){ return r.json() })
          .then(function(d){ window.location = '/thanks?o=' + d.id });
      }
    }).render('#paypal-button');
    </script>

    # in your controller:
    # POST /paypal/create  -> $pp->orders->checkout(...); return {id => $o->id}
    # POST /paypal/capture/:id -> $pp->orders->capture($id); return {id => ...}

=head1 SEE ALSO

=over 4

=item * L<https://developer.paypal.com/docs/api/orders/v2/>

=item * L<https://github.com/paypal/paypal-rest-api-specifications>

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
