# NAME

WebService::OANDA::ExchangeRates - A Perl wrapper for the OANDA Exchange Rates
API

# SYNOPSIS

    my $api = WebService::OANDA::ExchangeRates->new(api_key => 'YOUR_API_KEY');

    # all API methods return a response object

    # get_currencies
    my $response = $api->get_currencies();
    if ($response->is_success) {
        print $response->data->{USD}; # US Dollar
    }
    else {
      print $response->error_message # an error message
    }

    # get the number of quotes remaining
    $response = $api->get_remaining_quotes();
    print $response->data->{remaining_quotes} if $response->is_success;

    # get a series of quotes for a base currency
    $response = $api->get_rates(
        base_currency => 'USD',
        quote         => [ qw{ EUR CAD } ],
    );
    if ($response->is_success) {
        my $base_currency = $response->data->{base_currency};
        print "Base Currency: $base_currency\n";
        foreach my $quote_currency (keys %{$response->data->{quotes}) {
            my $quote = $response->data->{quotes}{$quote_currency};
            print "  $quote_currency:\n";
            print "    BID: ", $quote->{bid}, "\n";
            print "    ASK: ", $quote->{ask}, "\n";
        }
    }

# DESCRIPTION

This module provides a simple wrapper around the
[OANDA Exchange Rates API](http://www.oanda.com/rates) using [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).
Go to the
[API documentation page](http://developer.oanda.com/exchange-rates-api) for a
full reference of all the methods. This service requires you to
[sign up](http://www.oanda.com/rates/#pricing) for a trial or paying
subscription to obtain an API key.

# METHODS

## Constructor

- $api = WebService::OANDA::ExchangeRates->new(%options)

    The constructor for the API wrapper.  Other than `api_key` all other parameters
    are optional.

    - api\_key

        **REQUIRED** - the api key provided by the service

    - base\_url

            base_url => 'https://www.oanda.com/rates/api/v1/'

        The base url of the service. By default this is set to
        [https://www.oanda.com/rates/api/v1/](https://www.oanda.com/rates/api/v1/).  If your environment requires the
        service to be at a static IP address you can use
        [https://web-services.oanda.com/rates/api/v1/](https://web-services.oanda.com/rates/api/v1/).

    - proxy

            proxy => 'http://your.proxy.com:8080/'

        If you access the service behind a proxy, you can provide it. This sets the
        proxy for the underlying [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object. Similarly, if the
        `PERL_LWP_ENV_PROXY` environment variable is set with the proxy, it will be
        used automatically.

    - timeout

            timeout => 180

        Set the maximum time for a request to return on the underlying [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
        object. The default is 180 seconds.

## API Methods

All API methods return a [WebService::OANDA::ExchangeRates::Response](https://metacpan.org/pod/WebService::OANDA::ExchangeRates::Response) object
that provides access to the [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object and has deserialized the
JSON response into a native Perl data structure.

### get\_currencies(%options)

- $response = $api->get\_currencies()

    Returns the `/v1/currencies.json` endpoint; a hash of valid currency codes for
    the chosen dataset.

    **NOTE:** This endpoint usually returns an array of hashes which contain _code_
    and _description_ keys but `get_currencies()` massages them into a hash with
    the _code_ as the key and _description_ as the value.

    The data structure returned by `$response->data` will look something like this:

        {
            USD => 'US Dollar',
            EUR => 'Euro',
            CAD => 'Canadian Dollar',
            ...
        }

    - data\_set

        Which data set to use. The API, as of this writing, has two data sets.  They are
        the default _oanda_ rate or the _ecb_ (European Central Bank) rate. Each
        dataset tracks a different number of currencies.

        **DEFAULT:** oanda

            data_set => 'ecb'

### get\_remaining\_quotes

- $response = $api->get\_remaining\_quotes()

    Returns the `/v1/remaining_quotes.json` endpoint; the number of quote requests
    available in the current billing period.

    Some plans are limited to a specific number of quotes per billing period.  This
    endpoint can be used to determine how many quotes you have left.

    The data structure returned by `$response->data` will look something like this:

        {
          remaining_quotes => 100000,
        }

    For plans that have no quote limits, _remaining\_quotes_ will equal "unlimited".

### get\_rates

- $response = $api->get\_rates(%options)

    Returns the `/v1/rates/XXX.json` endpoint; a list of quotes for a specific base
    currency.

    This is the meat of the API and provides daily averages, highs, lows and
    midpoints for a each cross of currencies.  Only one argument is required,
    _base\_currency_.

    Please see the [OANDA Exchange Rates API Docs](http://developer.oanda.com/exchange-rates-api)
    for a breakdown of the returned data as it is a rather large data structure.

    - base\_currency

        **REQUIRED** - The base currency that all quotes are crossed against. Must be a
        valid 3 letter upper case currency code as provided by `/v1/currencies.json`
        endpoint.  This wrapper will not validate the currency code, just that it is
        in the correct format.

            base_currency => 'USD'

    - quote

        A single currency code, or an arrayref of currency codes to cross against the
        _base\_currency_.

        **DEFAULT:** All other available currencies.

            quote => 'EUR'
            quote => [qw{ EUR GBP CHF }]

    - data\_set

        Which data set to use. The API, as of this writing, has two data sets.  They are
        the default _oanda_ rate or the _ecb_ (European Central Bank) rate.

        **DEFAULT:** oanda

            data_set => 'ecb'

    - decimal\_places

        The number of decimal places to provide in the quote. May be a positive integer
        of reasonable size (as of this writing, up to 14) or the string "all".  Quotes
        that are requested with more precision than exist are padded out with zero's.

        **DEFAULT:** 5

            decimal_places => 'all'

    - fields

        Which fields to return in the quotes. This can be specified as a single string
        or an arrayref of strings.

        As of this writing, fields can be any of the following:

        - averages - the bid and ask
        - midpoint - the midpoint between the bid and ask
        - highs - the highest bid and ask
        - lows - the lowest bid and ask

        It should be noted that this module does not restrict what these strings are
        so as to be forward compatible with any changes. When using the `data_set`
        parameter for European Central Bank (ECB) rates, this parameter is ignored.

        **DEFAULT:** averages

            fields => 'all'
            fields => [qw{ averages midpoint }],

    - date

        The requested date for the quotes. This must be in _YYYY-MM-DD_ format.  The
        24 hour period of the date is considered to be that period in UTC.

        **DEFAULT:** The most recent quote

            date => '2014-02-01'

    - start, end

        This allows you to specify a date range. Also in _YYYY-MM-DD_ format.  When
        requesting a date range, quotes are modified such that:

        - averages (bid and ask) are the average of the daily values over the date range
        - midpoint (midpoint) is the midpoint between those averages
        - highs (high\_ask and high\_bid) are the highest values over the range
        - lows (low\_ask and low\_bid) are the lowest values over the range

        Specifying no `end` will assume today's date as the end point. Date ranges are
        inclusive (they include all quotes on and between `start` and `end`).

        **DEFAULT:** none

            start => '2014-01-01',
            end   => '2014-01-31',

## Accessors

### api\_key

> The originally supplied api\_key.

### base\_url

> Returns a [URI](https://metacpan.org/pod/URI) object

### proxy

> Returns a [URI](https://metacpan.org/pod/URI) object

### timeout

> The request timeout

### user\_agent

- $api->user\_agent

    This provides access to the underlying [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) instance.

    **NOTE:** While you can certainly modify the object to accomodate needed special
    settings, removing the default headers will cause authentication to fail.

# SEE ALSO

- [HTTP::Response](https://metacpan.org/pod/HTTP::Response)
- [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
- [URI](https://metacpan.org/pod/URI)
- [WebService::OANDA::ExchangeRates::Response](https://metacpan.org/pod/WebService::OANDA::ExchangeRates::Response)
- [OANDA Exchange Rates API](http://www.oanda.com/rates) landing page
- [OANDA Exchange Rates API Docs](http://developer.oanda.com/exchange-rates-api)

# SUPPORT

## Bug/Feature requests

Please file a ticket at the repository for this code on github at:

[https://github.com/oanda/perl-webservice-oanda-exchangerates](https://github.com/oanda/perl-webservice-oanda-exchangerates)

# AUTHOR

    Dave Doyle <ddoyle@oanda.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by OANDA Corporation.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
