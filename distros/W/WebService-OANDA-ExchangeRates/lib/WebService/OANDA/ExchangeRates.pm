package WebService::OANDA::ExchangeRates;

use JSON::XS;
use LWP::UserAgent;
use Moo;
use Types::Standard qw{ ArrayRef Int Str StrMatch };
use Type::Utils qw{ declare as where coerce from via enum};
use Types::URI qw{ Uri };
use WebService::OANDA::ExchangeRates::Response;

use vars qw($VERSION);
$VERSION = "0.003";

has base_url => (
    is       => 'ro',
    isa      => Uri,
    coerce   => Uri->coercion,
    default  => 'https://www.oanda.com/rates/api/v1/',
    required => 1,
);
has proxy => (
    is        => 'ro',
    isa       => Uri,
    coerce    => Uri->coercion,
    predicate => 1,
);
has timeout => ( is => 'ro', isa => Int, predicate => 1 );
has api_key => ( is => 'ro', isa => Str, required  => 1 );
has user_agent => ( is => 'ro', lazy => 1, builder => 1, init_arg => undef );

has _rates_validator => ( is => 'ro', required => 1, builder => 1 );

sub _build__rates_validator {

    # TYPES FOR VALIDATOR
    my $Currency = declare as StrMatch[qr{^[A-Z]{3}$}];
    my $Quotes   = declare as ArrayRef[$Currency];
    coerce $Quotes, from Str, via { [$_] };
    my $Date = declare as StrMatch[qr{^\d\d\d\d-\d\d-\d\d$}];
    my $Fields = declare as ArrayRef[Str];
    coerce $Fields, from Str, via { [$_] };
    my $DecimalPlaces = StrMatch[qr{^(?:\d+|all)$}];

    my %validators = (
        base_currency   => $Currency,
        quote           => $Quotes,
        date            => $Date,
        start           => $Date,
        end             => $Date,
        fields          => $Fields,
        decimal_places  => $DecimalPlaces,
        data_set        => Str,
    );

    return sub {
        my %params = @_;

        my %result = ();
        die "missing required parameter: base_currency"
            unless exists $params{base_currency};

        foreach my $key ( keys %params ) {
            my $type = $validators{$key};
            die "invalid parameter: $key" unless $type;
            my $val = $params{$key};
            $val = $type->coerce($val) if $type->has_coercion;
            if ( ! $type->check($val) ) {
                $val = JSON::XS::encode_json($val) if ref $val;
                die "invalid value: $key = ($val)";
            }
            $result{$key} = $val;
        }
        return \%result;

    }
}

sub _build_user_agent {
    my $self = shift;

    my %options = ( agent => sprintf '%s/%s', __PACKAGE__, $VERSION );

    # LWP::UA forces hostname verification by default in newer versions
    # turn off for simplification;
    $options{ssl_opts} = { verify_hostname => 0 }
        if $self->base_url->scheme eq 'https';
    $options{timeout} = $self->timeout if $self->has_timeout;

    my $ua = LWP::UserAgent->new(%options);

    # set auth header
    $ua->default_header(
        Authorization => sprintf 'Bearer %s', $self->api_key
    );

    # set the proxy if needed
    # LWP:UserAgent will use PERL_LWP_ENV_PROXY if set automatically
    $ua->proxy( $self->base_url->scheme, $self->proxy ) if $self->has_proxy;

    return $ua;
}

# GET /currencies.json
sub get_currencies {
    my $self = shift;
    my %params = @_;

    my $response = $self->_get_request('currencies.json', \%params);

    # convert arrayref[hashref] into hashref
    if ( $response->is_success && exists $response->data->{currencies}) {
        $response->data({
            map { $_->{code} => $_->{description} }
                @{$response->data->{currencies}}
        });
    }

    return $response;
}

# GET /rates/XXX.json
sub get_rates {
    my $self = shift;
    my $params = $self->_rates_validator->(@_);

    my $base_currency = delete $params->{base_currency};
    return $self->_get_request(['rates', $base_currency . '.json'], $params);
}

# GET /remaining_quotes.json
sub get_remaining_quotes {
    my $self = shift;
    return $self->_get_request('remaining_quotes.json');
}

sub _get_request {
    my ( $self, $path, $params ) = @_;

    my $uri = $self->base_url->clone->canonical;

    # build the new path
    $path = [$path] unless ref $path eq 'ARRAY';
    my @new_path = grep { $_ ne '' } ($uri->path_segments, @{$path});
    $uri->path_segments( @new_path );

    # set query params
    $params = {} unless defined $params;
    $uri->query_form(%{$params});

    my $response = $self->user_agent->get( $uri->as_string );
    return WebService::OANDA::ExchangeRates::Response->new(
        http_response => $response );
}

1;

__END__

=head1 NAME

WebService::OANDA::ExchangeRates - A Perl wrapper for the OANDA Exchange Rates
API

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module provides a simple wrapper around the
L<OANDA Exchange Rates API|http://www.oanda.com/rates> using L<LWP::UserAgent>.
Go to the
L<API documentation page|http://developer.oanda.com/exchange-rates-api> for a
full reference of all the methods. This service requires you to
L<sign up|http://www.oanda.com/rates/#pricing> for a trial or paying
subscription to obtain an API key.

=head1 METHODS

=head2 Constructor

=over 4

=item $api = WebService::OANDA::ExchangeRates->new(%options)

The constructor for the API wrapper.  Other than C<api_key> all other parameters
are optional.

=over 4

=item * api_key

B<REQUIRED> - the api key provided by the service

=item * base_url

  base_url => 'https://www.oanda.com/rates/api/v1/'

The base url of the service. By default this is set to
L<https://www.oanda.com/rates/api/v1/>.  If your environment requires the
service to be at a static IP address you can use
L<https://web-services.oanda.com/rates/api/v1/>.

=item * proxy

  proxy => 'http://your.proxy.com:8080/'

If you access the service behind a proxy, you can provide it. This sets the
proxy for the underlying L<LWP::UserAgent> object. Similarly, if the
C<PERL_LWP_ENV_PROXY> environment variable is set with the proxy, it will be
used automatically.

=item * timeout

  timeout => 180

Set the maximum time for a request to return on the underlying L<LWP::UserAgent>
object. The default is 180 seconds.

=back

=back

=head2 API Methods

All API methods return a L<WebService::OANDA::ExchangeRates::Response> object
that provides access to the L<HTTP::Response> object and has deserialized the
JSON response into a native Perl data structure.

=head3 get_currencies(%options)

=over 4

=item $response = $api->get_currencies()

Returns the C</v1/currencies.json> endpoint; a hash of valid currency codes for
the chosen dataset.

B<NOTE:> This endpoint usually returns an array of hashes which contain I<code>
and I<description> keys but C<get_currencies()> massages them into a hash with
the I<code> as the key and I<description> as the value.

The data structure returned by C<< $response->data >> will look something like this:

  {
      USD => 'US Dollar',
      EUR => 'Euro',
      CAD => 'Canadian Dollar',
      ...
  }

=over 4

=item * data_set

Which data set to use. The API, as of this writing, has two data sets.  They are
the default I<oanda> rate or the I<ecb> (European Central Bank) rate. Each
dataset tracks a different number of currencies.

B<DEFAULT:> oanda

  data_set => 'ecb'

=back

=back

=head3 get_remaining_quotes

=over 4

=item $response = $api->get_remaining_quotes()

Returns the C</v1/remaining_quotes.json> endpoint; the number of quote requests
available in the current billing period.

Some plans are limited to a specific number of quotes per billing period.  This
endpoint can be used to determine how many quotes you have left.

The data structure returned by C<< $response->data >> will look something like this:

  {
    remaining_quotes => 100000,
  }

For plans that have no quote limits, I<remaining_quotes> will equal "unlimited".

=back

=head3 get_rates

=over 4

=item $response = $api->get_rates(%options)

Returns the C</v1/rates/XXX.json> endpoint; a list of quotes for a specific base
currency.

This is the meat of the API and provides daily averages, highs, lows and
midpoints for a each cross of currencies.  Only one argument is required,
I<base_currency>.

Please see the L<OANDA Exchange Rates API Docs|http://developer.oanda.com/exchange-rates-api>
for a breakdown of the returned data as it is a rather large data structure.

=over 4

=item * base_currency

B<REQUIRED> - The base currency that all quotes are crossed against. Must be a
valid 3 letter upper case currency code as provided by C</v1/currencies.json>
endpoint.  This wrapper will not validate the currency code, just that it is
in the correct format.

  base_currency => 'USD'

=item * quote

A single currency code, or an arrayref of currency codes to cross against the
I<base_currency>.

B<DEFAULT:> All other available currencies.

  quote => 'EUR'
  quote => [qw{ EUR GBP CHF }]

=item * data_set

Which data set to use. The API, as of this writing, has two data sets.  They are
the default I<oanda> rate or the I<ecb> (European Central Bank) rate.

B<DEFAULT:> oanda

  data_set => 'ecb'

=item * decimal_places

The number of decimal places to provide in the quote. May be a positive integer
of reasonable size (as of this writing, up to 14) or the string "all".  Quotes
that are requested with more precision than exist are padded out with zero's.

B<DEFAULT:> 5

  decimal_places => 'all'

=item * fields

Which fields to return in the quotes. This can be specified as a single string
or an arrayref of strings.

As of this writing, fields can be any of the following:

=over 4

=item * averages - the bid and ask

=item * midpoint - the midpoint between the bid and ask

=item * highs - the highest bid and ask

=item * lows - the lowest bid and ask

=back

It should be noted that this module does not restrict what these strings are
so as to be forward compatible with any changes. When using the C<data_set>
parameter for European Central Bank (ECB) rates, this parameter is ignored.

B<DEFAULT:> averages

  fields => 'all'
  fields => [qw{ averages midpoint }],

=item * date

The requested date for the quotes. This must be in I<YYYY-MM-DD> format.  The
24 hour period of the date is considered to be that period in UTC.

B<DEFAULT:> The most recent quote

  date => '2014-02-01'

=item * start, end

This allows you to specify a date range. Also in I<YYYY-MM-DD> format.  When
requesting a date range, quotes are modified such that:

=over 4

=item * averages (bid and ask) are the average of the daily values over the date range

=item * midpoint (midpoint) is the midpoint between those averages

=item * highs (high_ask and high_bid) are the highest values over the range

=item * lows (low_ask and low_bid) are the lowest values over the range

=back

Specifying no C<end> will assume today's date as the end point. Date ranges are
inclusive (they include all quotes on and between C<start> and C<end>).

B<DEFAULT:> none

  start => '2014-01-01',
  end   => '2014-01-31',

=back

=back

=head2 Accessors

=head3 api_key

=over 4

The originally supplied api_key.

=back

=head3 base_url

=over 4

Returns a L<URI> object

=back

=head3 proxy

=over 4

Returns a L<URI> object

=back

=head3 timeout

=over 4

The request timeout

=back

=head3 user_agent

=over 4

=item $api->user_agent

This provides access to the underlying L<LWP::UserAgent> instance.

B<NOTE:> While you can certainly modify the object to accomodate needed special
settings, removing the default headers will cause authentication to fail.

=back

=head1 SEE ALSO

=over 4

=item * L<HTTP::Response>

=item * L<LWP::UserAgent>

=item * L<URI>

=item * L<WebService::OANDA::ExchangeRates::Response>

=item * L<OANDA Exchange Rates API|http://www.oanda.com/rates> landing page

=item * L<OANDA Exchange Rates API Docs|http://developer.oanda.com/exchange-rates-api>

=back

=head1 SUPPORT

=head2 Bug/Feature requests

Please file a ticket at the repository for this code on github at:

L<https://github.com/oanda/perl-webservice-oanda-exchangerates>

=head1 AUTHOR

  Dave Doyle <ddoyle@oanda.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by OANDA Corporation.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
