package WWW::PayPal::API::Orders;

# ABSTRACT: PayPal Checkout / Orders v2 API

use Moo;
use Carp qw(croak);
use WWW::PayPal::Order;
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
        # Pre-computed from paypal-rest-api-specifications
        # (openapi/checkout_orders_v2.json). Regenerate manually when the
        # spec changes.
        return {
            'orders.create'  => { method => 'POST',  path => '/v2/checkout/orders' },
            'orders.get'     => { method => 'GET',   path => '/v2/checkout/orders/{id}' },
            'orders.patch'   => { method => 'PATCH', path => '/v2/checkout/orders/{id}' },
            'orders.confirm' => { method => 'POST',  path => '/v2/checkout/orders/{id}/confirm-payment-source' },
            'orders.authorize' => { method => 'POST', path => '/v2/checkout/orders/{id}/authorize' },
            'orders.capture' => { method => 'POST',  path => '/v2/checkout/orders/{id}/capture' },
        };
    },
);


with 'WWW::PayPal::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::PayPal::Order->new(client => $self->client, data => $data);
}

sub checkout {
    my ($self, %args) = @_;

    croak 'amount required'     unless defined $args{amount};
    croak 'currency required'   unless defined $args{currency};
    croak 'return_url required' unless defined $args{return_url};
    croak 'cancel_url required' unless defined $args{cancel_url};

    my $currency = $args{currency};
    my $amount   = $args{amount};

    my $pu = {
        amount => { currency_code => $currency, value => $amount },
    };
    $pu->{description}     = $args{description}     if defined $args{description};
    $pu->{invoice_id}      = $args{invoice_id}      if defined $args{invoice_id};
    $pu->{custom_id}       = $args{custom_id}       if defined $args{custom_id};
    $pu->{soft_descriptor} = $args{soft_descriptor} if defined $args{soft_descriptor};
    $pu->{reference_id}    = $args{reference_id}    if defined $args{reference_id};

    if ($args{items} && @{ $args{items} }) {
        my @items;
        my $item_total = 0;
        for my $i (@{ $args{items} }) {
            my $unit = $i->{unit_amount} // $i->{price}
                or croak 'item unit_amount required';
            my $qty  = $i->{quantity} // 1;
            push @items, {
                name        => $i->{name} // croak('item name required'),
                quantity    => "$qty",
                unit_amount => {
                    currency_code => $i->{currency_code} // $currency,
                    value         => "$unit",
                },
                (defined $i->{sku}         ? (sku         => $i->{sku})         : ()),
                (defined $i->{description} ? (description => $i->{description}) : ()),
                (defined $i->{category}    ? (category    => $i->{category})    : ()),
            };
            $item_total += $unit * $qty;
        }
        $pu->{items} = \@items;
        # PayPal requires a breakdown when items are present
        $pu->{amount}{breakdown} = {
            item_total => {
                currency_code => $currency,
                value         => sprintf('%.2f', $item_total),
            },
        };
    }

    $pu->{shipping} = $args{shipping} if $args{shipping};

    my %create = (
        intent         => $args{intent} // 'CAPTURE',
        purchase_units => [$pu],
        return_url     => $args{return_url},
        cancel_url     => $args{cancel_url},
    );
    for my $k (qw(brand_name locale user_action shipping_preference payer)) {
        $create{$k} = $args{$k} if defined $args{$k};
    }

    return $self->create(%create);
}


sub create {
    my ($self, %args) = @_;

    croak 'intent required' unless $args{intent};
    croak 'purchase_units required'
        unless ref $args{purchase_units} eq 'ARRAY' && @{$args{purchase_units}};

    my $body = {
        intent         => $args{intent},
        purchase_units => $args{purchase_units},
    };

    # Application context: return/cancel URLs and branding
    my %ctx;
    $ctx{return_url}   = $args{return_url} if $args{return_url};
    $ctx{cancel_url}   = $args{cancel_url} if $args{cancel_url};
    $ctx{brand_name}   = $args{brand_name} if $args{brand_name};
    $ctx{locale}       = $args{locale}     if $args{locale};
    $ctx{user_action}  = $args{user_action} // 'PAY_NOW';
    $ctx{shipping_preference} = $args{shipping_preference}
        if $args{shipping_preference};
    if (%ctx) {
        # PayPal supports both payment_source.paypal.experience_context (new)
        # and application_context (legacy). We use application_context for
        # broad compatibility.
        $body->{application_context} = \%ctx;
    }

    $body->{payer} = $args{payer} if $args{payer};

    my $data = $self->call_operation('orders.create', body => $body);
    return $self->_wrap($data);
}


sub get {
    my ($self, $id) = @_;
    croak 'order id required' unless $id;
    my $data = $self->call_operation('orders.get', path => { id => $id });
    return $self->_wrap($data);
}


sub capture {
    my ($self, $id, %args) = @_;
    croak 'order id required' unless $id;

    my $data = $self->call_operation('orders.capture',
        path => { id => $id },
        body => $args{body} || {},
    );
    return $self->_wrap($data);
}


sub authorize {
    my ($self, $id, %args) = @_;
    croak 'order id required' unless $id;
    my $data = $self->call_operation('orders.authorize',
        path => { id => $id },
        body => $args{body} || {},
    );
    return $self->_wrap($data);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Orders - PayPal Checkout / Orders v2 API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $order = $pp->orders->create(
        intent         => 'CAPTURE',
        purchase_units => [{
            amount => { currency_code => 'EUR', value => '42.00' },
        }],
        return_url => 'https://example.com/paypal/return',
        cancel_url => 'https://example.com/paypal/cancel',
    );

    my $same = $pp->orders->get($order->id);
    my $done = $pp->orders->capture($order->id);

=head1 DESCRIPTION

Controller for PayPal's Checkout / Orders v2 API. Dispatches via cached
OpenAPI C<operationId> entries.

=head2 client

The parent L<WWW::PayPal> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 checkout

    my $order = $pp->orders->checkout(
        amount     => '9.99',
        currency   => 'EUR',
        return_url => 'https://example.com/paypal/return',
        cancel_url => 'https://example.com/paypal/cancel',

        # optional
        intent              => 'CAPTURE',       # or 'AUTHORIZE'
        brand_name          => 'Amiga Event',
        locale              => 'de-DE',
        user_action         => 'PAY_NOW',       # default
        shipping_preference => 'NO_SHIPPING',   # or GET_FROM_FILE / SET_PROVIDED_ADDRESS
        description         => 'Ticket XYZ',
        invoice_id          => 'INV-2026-0042',
        custom_id           => 'user-123',
        soft_descriptor     => 'AMIGAEVENT',
        reference_id        => 'cart-42',
        items => [
            { name => 'Ticket', quantity => 1, unit_amount => '9.99', sku => 'T1' },
        ],
        shipping => {
            name    => { full_name => 'Jane Doe' },
            address => { country_code => 'DE', postal_code => '10115', ... },
        },
    );

    $c->redirect_to($order->approve_url);

High-level convenience wrapper around L</create> — the modern replacement
for the NVP ExpressCheckout flow. Builds the C<purchase_units> and
C<application_context> structures for the common single-item checkout so
callers don't have to.

When C<items> is given, the amount C<breakdown.item_total> is filled in
automatically (PayPal requires it as soon as items are present).

For multi-unit orders, multi-seller orders, or anything else outside this
happy path, use L</create> directly.

=head2 create

    my $order = $pp->orders->create(
        intent         => 'CAPTURE',
        purchase_units => [ ... ],
        return_url     => '...',
        cancel_url     => '...',
    );

Creates an order and returns a L<WWW::PayPal::Order>. The buyer must be
redirected to C<< $order->approve_url >> to approve the payment.

=head2 get

    my $order = $pp->orders->get($id);

Fetches an order by ID.

=head2 capture

    my $order = $pp->orders->capture($id);

Captures an approved order. Returns the updated L<WWW::PayPal::Order> with a
completed capture attached.

=head2 authorize

    my $order = $pp->orders->authorize($id);

Places an authorization on an approved order (alternative to immediate
capture).

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
