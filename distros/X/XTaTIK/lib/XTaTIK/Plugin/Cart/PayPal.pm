package XTaTIK::Plugin::Cart::PayPal;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious::Controller';
use utf8;
use experimental 'postderef';

my @CHECKOUT_FORM_FIELDS = qw/
    address1  address2  city  do_save_address  email
    lname  name  phone  promo_code  province  toc  zip
/;

my %TEMPLATES = qw{
    thank_you          cart/Plugins/PayPal/thank_you
    checkout           cart/Plugins/PayPal/checkout
    checkout_review    cart/Plugins/PayPal/checkout_review
    email_to_customer  cart/Plugins/PayPal/email/order-to-customer
    email_to_company   cart/Plugins/PayPal/email/order-to-company
};

sub _add_routes {
    my ( $self, $rc ) = @_;

    my ( $ns, $c ) = qw/XTaTIK::Plugin::Cart  PayPal/;
    $rc->any('/thank-you')
        ->to( namespace => $ns, controller => $c, action => 'thank_you' );
    $rc->post('/checkout')
        ->to( namespace => $ns, controller => $c, action => 'checkout' );
    $rc->post('/checkout-review')
        ->to( namespace => $ns, controller => $c, action => 'checkout_review');
}

## ROUTES
sub thank_you {
    my $self = shift;

    return $self->redirect_to('/cart/')
        unless @{$self->cart->all_items}
            and $self->param('cart_id') eq $self->cart->id;

    my $order_num = sprintf $self->xtext('order_number'), $self->cart->id;
    my $quote_num = sprintf $self->xtext('quote_number'), $self->cart->id;

    my ( $cart, $quote ) = $self->cart->all_items_cart_quote;
    $self->cart->submit(
        map +( $_ => $self->session('customer_data')->{$_} ),
            qw/address1  address2  city  email  lname  name  phone
                province  zip/
    );

    my $cart_title  = @$cart  ? "Order #$order_num " : '';
    my $quote_title = @$quote ? "Quote #$quote_num " : '';
    $self->stash(
        cart          => $cart,
        quote         => $quote,
        visitor_ip    => $self->tx->remote_address,
        order_number  => $order_num,
        quote_number  => $quote_num,
        $self->_costs,
        title => "Your $cart_title $quote_title on "
                . $self->config('text')->{website_domain},
    );

    # Send order email to customer
    eval { # eval, since we don't know what address we're trying to send to
        $self->mail(
            test     => $self->config('mail')->{test},
            to       => $self->session('customer_data')->{email},
            from     => $self->config('mail')->{from}{order},
            subject  => $self->stash('title'),
            type     => 'text/html',
            data     => $self->render_to_string($TEMPLATES{email_to_customer}),
        );
    };

    $self->stash(
        title => "New $cart_title $quote_title on "
                . $self->config('text')->{website_domain},
        promo_code => $self->session('customer_data')->{promo_code} // 'N/A',
        map +( "cust_$_" => $self->session('customer_data')->{$_} ),
            qw/address1  address2  city  email  lname  name  phone
                province  zip/, map +( $_->{email} ? $_->{email} : () ),
                            @{ $self->xtext('paypal_custom_fields') || [] },
    );

    #Send order email to ourselves
    $self->mail(
        test    => $self->config('mail')->{test},
        to      => $self->config('mail')->{to}{order},
        from    => $self->config('mail')->{from}{order},
        subject => $self->stash('title'),
        type    => 'text/html',
        data    => $self->render_to_string( $TEMPLATES{email_to_company} ),
    );

    # TODO: there's gotta be a nicer way of doing this...
    # ... maybe stuff it into ->submit()
    $self->stash(__cart => undef);
    $self->session(cart_id => undef);
    $self->cart;
    $self->cart_dollars('refresh');
    $self->cart_cents('refresh');

    $self->stash( template => $TEMPLATES{thank_you} );
}

sub checkout {
    my $self = shift;

    my @ids = map /(\d+)/, grep /^id/, $self->req->params->names->@*;

    for ( @ids ) {
        $self->cart->alter_quantity(
            $self->param('number_'   . $_),
            $self->param('quantity_' . $_)
        );
    }
    @ids and $self->cart->save;
    $self->cart_dollars('refresh'); $self->cart_cents('refresh');

    for ( @CHECKOUT_FORM_FIELDS ) {
        next if length $self->param($_);

        $self->param( $_ => $self->geoip_region )
            if $_ eq 'province' and not length $self->session($_);

        next unless length $self->session($_);
        $self->param( $_ => $self->session($_) );
    }

    my %items = $self->cart->all_items_cart_quote_kv;
    $items{cart}->@* or $items{quote}->@*
        or return $self->redirect_to('/cart/');
    $self->stash(
        %items,
        template => $TEMPLATES{checkout}
    );
}

sub checkout_review {
    my $self = shift;

    $_->{callback} and $_->{callback}->( $self )
        for @{ $self->xtext('paypal_custom_fields') || [] };

    $self->session(
        customer_data => {
            map +( $_ => $self->param($_) ), qw/
                address1  address2  city  email
                lname  name  phone  promo_code  province  zip
            /, map +( $_->{email} ? $_->{email} : () ),
                @{ $self->xtext('paypal_custom_fields') || [] },
        },
    );

    my ( $cart ) = $self->cart->all_items_cart_quote;
    @$cart or $self->redirect_to('/cart/thank-you');

    if ( $self->param('do_save_address') ) {
        $self->session( $_ => $self->param($_) )
        for @CHECKOUT_FORM_FIELDS;
    }
    else {
        $self->session( $_ => undef )
            for @CHECKOUT_FORM_FIELDS;
    }

    $self->form_checker(
        rules => {
            email    => {
                max => 300,
                email => 'Email',
            },
            name    => {
                max => 300,
                name => 'First name',
            },
            lname    => {
                max => 300,
                name => 'Last name',
            },
            address1 => {
                max => 1000,
                name => 'Address line 1',
            },
            address2 => {
                max => 1000,
                name => 'Address line 2',
                optional => 1,
            },
            city    => {
                max => 300,
            },
            do_save_address => {
                optional => 1,
                select => 1,
            },
            province=> {
                valid_values => [
                    qw/AB BC MB NB NL NT NS NU ON PE QC SK YT/
                ],
                valid_values_error => 'Please specify province',
            },
            zip => {
                max => 20,
                name => 'Postal code',
            },
            phone => {
                name => 'Phone number',
            },
            toc => {
                mandatory_error => 'You must accept Terms and Conditions',
            },
            promo_code => {
                name => 'Promo code',
                optional => 1,
                max => 100,
            },
        },
    );

    unless ( $self->form_checker_ok ) {
        $self->flash(
            form_checker_error_wrapped => $self->form_checker_error_wrapped,
        );
        $self->stash( cart => $cart );
        $self->render(template => $TEMPLATES{checkout});
        return;
    }

    my $custom = $self->xtext('paypal_custom');
    $custom =~ s/\$promo_code/$self->param('promo_code')/ge;
    $custom =~ s/\$(\S+)/$self->param($1)/ge;

    $self->stash(
        $self->cart->all_items_cart_quote_kv,
        custom        => $custom,
        $self->_costs,
        template => $TEMPLATES{checkout_review},
    )
}

## AUXILIARY

sub __cur($) {
    return sprintf '%.02f', shift//0;
}

sub _costs {
    my $self = shift;

    my ( $shipping, $gst, $hst, $pst, $total_d, $total_c);
    my $xtext_tax = $self->xtext('PST')->{
        $self->param('province')
        // ($self->session('customer_data') || {})->{province}
    };

    if ( ref $xtext_tax ) {
        my $hst_rate = $$xtext_tax / 100;
        $hst      = __cur $self->cart->total * $hst_rate;
        $shipping = __cur( defined( $self->xtext('shipping_free') )
            && $self->xtext('shipping_free') < $self->cart->total
            ? 0 : $self->xtext('shipping') );

        ( $total_d, $total_c ) = split /\./,
            __cur +($self->cart->total + $shipping) * (1+$hst_rate);
        $shipping *=  1 + $hst_rate;
    }
    else {
        my $pst_rate = $xtext_tax / 100;
        my $gst_rate = $self->xtext('GST') / 100;
        $gst = __cur $self->cart->total * $gst_rate;
        $pst = __cur $self->cart->total * $pst_rate;
        $shipping = __cur(  defined( $self->xtext('shipping_free') )
            && $self->xtext('shipping_free') < $self->cart->total
            ? 0 : $self->xtext('shipping') );

        ( $total_d, $total_c ) = split /\./,
            __cur +($self->cart->total + $shipping) * (1+$pst_rate+$gst_rate);
        $shipping *= 1 + $pst_rate + $gst_rate;

    }

    return (
        gst             => __cur $gst//0,
        pst             => __cur $pst//0,
        hst             => __cur $hst//0,
        shipping        => __cur $shipping,
        total_dollars   => $total_d,
        total_cents     => $total_c,
    );
}

1;

__END__


=pod


=cut