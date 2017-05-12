# NAME

WebService::PayPal::NVP - PayPal NVP API

# VERSION

version 0.006

# SYNOPSIS

    use feature qw( say );

    my $nvp = WebService::PayPal::NVP->new(
        user   => 'user.tld',
        pwd    => 'xxx',
        sig    => 'xxxxxxx',
        branch => 'sandbox',
    );

    my $res = $nvp->set_express_checkout({
        DESC              => 'Payment for something cool',
        AMT               => 25.00,
        CURRENCYCODE      => 'GBP',
        PAYMENTACTION     => 'Sale',
        RETURNURL         => "http://returnurl.tld",
        CANCELURL         => "http//cancelurl.tld",
        LANDINGPAGE       => 'Login',
        ADDOVERRIDE       => 1,
        SHIPTONAME        => "Customer Name",
        SHIPTOSTREET      => "7 Customer Street",
        SHIPTOSTREET2     => "",
        SHIPTOCITY        => "Town",
        SHIPTOZIP         => "Postcode",
        SHIPTOEMAIL       => "customer\@example.com",
        SHIPTOCOUNTRYCODE => 'GB',
    });

    if ($res->success) {
        # timestamps turned into DateTime objects
        say "Response received at "
            . $res->timestamp->dmy . " "
            . $res->timestamp->hms(':');

        say $res->token;

        for my $arg ($res->args) {
            if ($res->has_arg($arg)) {
                say "$arg => " . $res->$arg;
            }
        }

        # get a redirect uri to paypal express checkout
        # the Response object will automatically detect if you have
        # live or sandbox and return the appropriate url for you
        if (my $redirect_user_to = $res->express_checkout_uri) {
            ...;
        }
    }
    else {
        say $_
          for @{$res->errors};
    }

# DESCRIPTION

A pure object oriented interface to PayPal's NVP API (Name-Value Pair). A lot of the logic in this module was taken from [Business::PayPal::NVP](https://metacpan.org/pod/Business::PayPal::NVP). I re-wrote it because it wasn't working with Catalyst adaptors and I couldn't save instances of it in Moose-type accessors. Otherwise it worked fine. So if you don't need that kind of support you should visit [Business::PayPal::NVP](https://metacpan.org/pod/Business::PayPal::NVP)!.
Another difference with this module compared to Business::PayPal::NVP is that the keys may be passed as lowercase. Also, a response will return a WebService::PayPal::NVP::Response object where the response values are methods. Timestamps will automatically be converted to DateTime objects for your convenience.

# METHODS

## api\_ver

The version of PayPal's NVP API which you would like to use.  Defaults to 51.

## errors

Returns an `ArrayRef` of errors.  The ArrayRef is empty when there are no
errors.

## has\_errors

Returns true if `errors()` is non-empty.

## create\_recurring\_payments\_profile( $HashRef )

## do\_direct\_payment( $HashRef )

## do\_express\_checkout\_payment( $HashRef )

## get\_express\_checkout\_details( $HashRef )

## get\_recurring\_payments\_profile\_details( $HashRef )

## get\_transaction\_details( $HashRef )

## manage\_recurring\_payments\_profile\_status( $HashRef )

## mass\_pay( $HashRef )

## refund\_transaction( $HashRef )

## set\_express\_checkout( $HashRef )

## transaction\_search( $HashRef )

## ua( LWP::UserAgent->new( ... ) )

This method allows you to provide your own UserAgent.  This object must be of
the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) family, so [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) modules will also work.

## url

The PayPal URL to use for requests.  This can be helpful when mocking requests.
Defaults to PayPals production or sandbox URL as appropriate.

# TESTING

The main test will not work out of the box, because obviously it needs some sandbox/live api details before it can proceed. Simply create an `auth.yml` file in the distribution directory with the following details:

    ---
    user: 'api_user'
    pass: 'api password'
    sig:  'api signature'
    branch: 'sandbox or live'

If it detects the file missing completely it will just skip every test. Otherwise, it will only fail if any of the required information is missing.

# AUTHOR

Brad Haywood <brad@geeksware.com>

# CREDITS

A lot of this module was taken from [Business::PayPal::NVP](https://metacpan.org/pod/Business::PayPal::NVP) by Scott Wiersdorf.
It was only rewritten in order to work properly in [Catalyst::Model::Adaptor](https://metacpan.org/pod/Catalyst::Model::Adaptor).

## THANKS

A huge thanks to Olaf Alders (OALDERS) for all of his useful pull requests!

# AUTHOR

Brad Haywood <brad@perlpowered.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2017 by Brad Haywood.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
