# NAME

WebService::PayPal::PaymentsAdvanced - A simple wrapper around the PayPal Payments Advanced web service

# VERSION

version 0.000021

# SYNOPSIS

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(
        {
            password => 'seekrit',
            user     => 'username',
            vendor   => 'somevendor',
        }
    );

    my $response = $payments->create_secure_token(
        {
            AMT            => 100,
            TRXTYPE        => 'S',
            BILLINGTYPE    => 'MerchantInitiatedBilling',
            CANCELURL      => 'https://example.com/cancel',
            ERRORURL       => 'https://example.com/error',
            L_BILLINGTYPE0 => 'MerchantInitiatedBilling',
            NAME           => 'Chuck Norris',
            RETURNURL      => 'https://example.com/return',
        }
    );

    my $uri = $response->hosted_form_uri;

    # Store token data for later use.  You'll need to implement this yourself.
    $foo->freeze_token_data(
        token    => $response->secure_token,
        token_id => $response->secure_token_id,
    );

    # Later, when PayPal returns a silent POST or redirects the user to your
    # return URL:

    my $redirect_response = $payments->get_response_from_redirect(
        ip_address => $ip,
        params     => $params,
    );

    # Fetch the tokens from the original request. You'll need to implement
    # this yourself.

    my $thawed = $foo->get_thawed_tokens(...);

    # Don't do anything until you're sure the tokens are ok.
    if (   $thawed->secure_token ne $redirect->secure_token
        || $thawed->secure_token_id ne $response->secure_token_id ) {
        die 'Fraud!';
    }

    # Everything looks good.  Carry on!

    print $response->secure_token;

# DESCRIPTION

BETA BETA BETA.  The interface is still subject to change.

This is a wrapper around the "PayPal Payments Advanced" (AKA "PayPal Payflow
Link") hosted forms.  This code does things like facilitating secure token
creation, providing an URL which you can use to insert an hosted\_form into
your pages and processing the various kinds of response you can get from
PayPal.

We also use various exception classes to make it easier for you to decide how
to handle the parts that go wrong.

# OBJECT INSTANTIATION

The following parameters can be supplied to `new()` when creating a new object.

## Required Parameters

### password

The value of the `password` field you use when logging in to the Payflow
Manager.  (You'll probably want to create a specific user just for API calls).

### user

The value of the `user` field you use when logging in to the Payflow Manager.

### vendor

The value of the `vendor` field you use when logging in to the Payflow
Manager.

## Optional Parameters

### nonfatal\_result\_codes

An arrayref of result codes that will be treated as non-fatal (i.e., that will
not cause an exception). By default, only 0 is considered non-fatal, but
depending on your integration, other codes such as 112 (failed AVS check) may
be considered non-fatal.

### partner

The value of the `partner` field you use when logging in to the Payflow
Manager. Defaults to `PayPal`.

### payflow\_pro\_uri

The hostname for the Payflow Pro API.  This is where token creation requests
get directed.  This already has a sensible (and correct) default, but it is
settable so that you can more easily mock API calls when testing.

### payflow\_link\_uri

The hostname for the Payflow Link website.  This is the hosted service where
users will enter their payment information.  This already has a sensible (and
correct) default, but it is settable in case you want to mock it while testing.

### production\_mode

This is a `Boolean`.  Set this to `true` if when you are ready to process
real transactions.  Defaults to `false`.

### ua

You may provide your own UserAgent, but it must be of the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
family.  If you do provide a UserAgent, be sure to set a sensible timeout
value. Requests to the web service frequently run 20-30 seconds.

This can be useful for debugging.  You'll be able to get detailed information
about the network calls which are being made.

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use LWP::UserAgent;
    use WebService::PayPal::PaymentsAdvanced;

    my $ua = LWP::UserAgent;
    debug_ua($ua);

    my $payments
        = WebService::PayPal::PaymentsAdvanced->new( ua => $ua, ... );

    # Now fire up a console and watch your network activity.

Check the tests which accompany this distribution for an example of how to mock
API calls using [Test::LWP::UserAgent](https://metacpan.org/pod/Test::LWP::UserAgent).

### validate\_hosted\_form\_uri

`Boolean`.  If enabled, this module will attempt to GET the uri which you'll
be providing to the end user.  This can help you identify issues on the PayPal
side.  This is helpful because you'll be able to log exceptions thrown by this
method and deal with them accordingly.  If you disable this option, you'll need
to rely on end users to report issues which may exist within PayPal's hosted
pages.  Defaults to `true`.

### verbose

`Boolean`.  Sets `VERBOSITY=HIGH` on all transactions if enabled.  Defaults
to `true`.

## Methods

### create\_secure\_token

Create a secure token which you can use to create a hosted form uri.  Returns a
[WebService::PayPal::PaymentsAdvanced::Response::SecureToken](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response::SecureToken) object.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->create_secure_token(
        {
            AMT            => 100,
            TRXTYPE        => 'S',
            BILLINGTYPE    => 'MerchantInitiatedBilling',
            CANCELURL      => 'https://example.com/cancel',
            ERRORURL       => 'https://example.com/error',
            L_BILLINGTYPE0 => 'MerchantInitiatedBilling',
            NAME           => 'Chuck Norris',
            RETURNURL      => 'https://example.com/return'
        }
    );

    print $response->secure_token;

### get\_response\_from\_redirect

This method can be used to parse responses from PayPal to your return URL.
It's essentially a wrapper around
[WebService::PayPal::PaymentsAdvanced::Response::FromRedirect](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response::FromRedirect).  Returns a
[WebService::PayPal::PaymentsAdvanced::Response](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response) object.

    my $response = $payments->get_response_from_redirect(
        params     => $params,
    );
    print $response->message;

### get\_response\_from\_silent\_post

This method can be used to validate responses from PayPal to your silent POST
url.  If you provide an ip\_address parameter, it will be validated against a
list of known IPs which PayPal provides.  You're encouraged to provide an IP
address in order to prevent spoofing of payment responses.  See
[WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST) for more
information on this behaviour.

This method returns a
[WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::PayPal](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::PayPal)
object for PayPal transactions.  It returns a
[WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::CreditCard](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::CreditCard)
object for credit card transactions.  You can either inspect the class return
to you or use the `is_credit_card_transaction` or `is_paypal_transaction`
methods to learn which method the customer paid with.  Both methods return a
`Boolean`.

    my $response = $payments->get_response_from_redirect(
        ip_address => $ip,
        params     => $params,
    );
    print $response->message. "\n";
    if ( $response->is_credit_card_transaction ) {
        print $response->card_type, q{ }, $response->card_expiration;
    }

### post

Generic method to post arbitrary params to PayPal.  Requires a `HashRef` of
parameters and returns a [WebService::PayPal::PaymentsAdvanced::Response](https://metacpan.org/pod/WebService::PayPal::PaymentsAdvanced::Response)
object.  Any lower case keys will be converted to upper case before this
response is sent.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->post( { TRXTYPE => 'V', ORIGID => $pnref, } );
    say $response->message;

    # OR
    my $response = $payments->post( { trxtype => 'V', origid => $pnref, } );

### capture\_delayed\_transaction( $ORIGID, \[$AMT\] )

Captures a sale which you have previously authorized.  Requires the ID of the
original transaction.  If you wish to capture an amount which is not equal to
the original authorization amount, you'll need to pass an amount as the second
parameter.  Returns a response object.

### auth\_from\_credit\_card\_reference\_transaction( $ORIGID, $amount, $extra )

Process a authorization based on a reference transaction from a credit card.
Requires 2 arguments: an ORIGID from a previous credit card transaction and an
amount. Any additional parameters can be passed via a HashRef as an optional
3rd argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->auth_from_credit_card_reference_transaction(
        'BFOOBAR', 1.50', { INVNUM => 'FOO123' }
    );
    say $response->message;

### sale\_from\_credit\_card\_reference\_transaction( $ORIGID, $amount )

Process a sale based on a reference transaction from a credit card.  See
Requires 2 arguments: an ORIGID from a previous credit card transaction and an
amount.  Any additional parameters can be passed via a HashRef as an optional
3rd argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->sale_from_credit_card_reference_transaction(
        'BFOOBAR', 1.50', { INVNUM => 'FOO123' }
    );
    say $response->message;

### auth\_from\_paypal\_reference\_transaction( $BAID, $amount, $currency, $extra )

Process an authorization based on a reference transaction from PayPal.
Requires 3 arguments: a BAID from a previous PayPal transaction, an amount and
a currency.  Any additional parameters can be passed via a HashRef as the
optional fourth argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->auth_from_paypal_reference_transaction(
        'B-FOOBAR', 1.50, 'USD', { INVNUM => 'FOO123' }
    );
    say $response->message;

### sale\_from\_paypal\_reference\_transaction( $BAID, $amount, $currency, $extra )

Process a sale based on a reference transaction from PayPal.  Requires 3
arguments: a BAID from a previous PayPal transaction, an amount and a currency.
Any additional parameters can be passed via a HashRef as an optional fourth
argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->sale_from_paypal_reference_transaction(
        'B-FOOBAR', 1.50, 'USD', { INVNUM => 'FOO123' }
    );
    say $response->message;

### refund\_transaction( $origid, \[$amount\] )

Refunds (credits) a previous transaction.  Requires the `ORIGID` and an
optional `AMT`.  If no amount is provided, the entire transaction will be
refunded.

### inquiry\_transaction( $HashRef )

Performs a transaction inquiry on a previously submitted transaction.  Requires
the ID of the original transaction.  Returns a response object.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $inquiry = $payments->inquiry_transaction(
        { ORIGID => 'FOO123', TENDER => 'C', }
    );
    say $response->message;

### void\_transaction( $ORIGID )

Voids a previous transaction.  Requires the ID of the transaction to void.
Returns a response object.

# SEE ALSO

The official [Payflow Gateway Developer Guide and
Reference](https://developer.paypal.com/docs/classic/payflow/integration-guide/)

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>
- Mark Fowler <mark@twoshortplanks.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
