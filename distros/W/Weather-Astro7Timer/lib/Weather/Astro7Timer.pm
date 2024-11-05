package Weather::Astro7Timer;

use 5.006;
use strict;
use warnings;

use Carp;
use Time::Local;

use parent 'Weather::API::Base';
use Weather::API::Base qw(:all);

=head1 NAME

Weather::Astro7Timer - Simple client for the 7Timer.info Weather Forecast service

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

  use Weather::Astro7Timer;

  my $w7t = Weather::Astro7Timer->new();

  # Get ASTRO weather for the Stonehenge area

  my %report = $w7t->get(
      product => 'astro',    # Forecast type (astro, civil, civillight, meteo)
      lat     => 51.2,       # Latitude
      lon     => -1.8,       # Longitude
  );

  # Dumping the result would give you:
  %report = {
      'product'    => 'astro',
      'init'       => '2023032606',
      'dataseries' => [{
              'temp2m'  => 6,
              'wind10m' => {
                  'speed'     => 2,
                  'direction' => 'NE'
              },
              'rh2m'         => 13,
              'seeing'       => 3,
              'timepoint'    => 3,
              'lifted_index' => 2,
              'prec_type'    => 'none',
              'cloudcover'   => 9,
              'transparency' => 6
          },
          {...},
          ...
      ]
  };

  # You can get a png image instead...

  my $data = $w7t->get(
      product => 'civil',
      lat     => 51.2,
      lon     => -1.8,
      output  => 'png'
  );

  # ... and write it out to a file
  open(my $fh, '>', "civil.png") or die $!; print $fh $data; close($fh);


=head1 DESCRIPTION

Weather::Astro7Timer provides basic access to the L<7Timer.info|https://7Timer.info>
Weather Forecast API.
7Timer is a service based on NOAA's GFS and provides various types of forecast products.
It is mostly known for its ASTRO product intended for astronomers and stargazers, as
it provides an astronomical seeing and transparency forecast.

Please see the L<official API documentation|https://www.7timer.info/doc.php> and
L<GitHub Wiki|https://github.com/Yeqzids/7timer-issues/wiki/Wiki> for details.

The module was made to serve the apps L<Xasteria|https://astro.ecuadors.net/xasteria/> and
L<Polar Scope Align|https://astro.ecuadors.net/polar-scope-align/>, but if your service
requires some extra functionality, feel free to contact the author about it.

=head1 CONSTRUCTOR

=head2 C<new>

    my $w7t = Weather::Astro7Timer->new(
        scheme  => $http_scheme?,
        timeout => $timeout_sec?,
        agent   => $user_agent_string?,
        ua      => $lwp_ua?,
        error   => $die_or_return?
    );
  
Optional parameters:

=over 4

=item * C<scheme> : You can specify C<http>. Default: C<https>.

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<agent> : Customize the user agent string.

=item * C<ua> : Pass your own L<LWP::UserAgent> to customise further (overrides C<agent>).

=item * C<error> : Pass C<'die'> to die on error. Default is C<'return'>.

=back

=head1 METHODS

=head2 C<get>

    my $report = $w7t->get(
        product => $product,   # Forecast type (astro, civil, civillight, meteo, two)
        lat     => $lat,       # Latitude
        lon     => $lon,       # Longitude
        output  => $format?,   # Output format (default json)
        unit    => $unit?,     # Units (default metric)
        lang    => $language?, # Language (default en)
        tzshift => $tz_shift?, # Timezone shift from UTC (hours, default 0)
        ac      => $alt_cor?,  # Altitude correction (default 0)
    );

    my %report = $w7t->get( ... );


Fetches a forecast report for the requested for the requested location.
Returns a string containing the JSON or XML data, except in array context, in which case,
as a convenience, it will use L<JSON> or L<XML::Simple> to decode it directly to a Perl hash
(in the case of C<png> output, the hash will containing a single key C<data> with the png data).
For an explanation to the returned data, refer to the L<official API documentation|http://www.7timer.info/doc.php>.

If the request is not successful, it will C<die> throwing the C<< HTTP::Response->status_line >>.

Required parameters:

=over 4
 
=item * C<lat> : Latitude (-90 to 90). South is negative.

=item * C<lon> : Longitude (-180 to 180). West is negative.

=item * C<product> : Choose from the available forecast products:

=over 4

=item * C<astro> : ASTRO 3-day forecast for astronomy/stargazing with 3h step (includes astronomical seeing, transparency).

=item * C<civil> : CIVIL 8-day forecast that provides a weather type enum (see docs for equivalent icons) with 3h step.

=item * C<civillight> : CIVIL Light simplified per-day forecast for next week.

=item * C<meteo> : A detailed meteorological forecast including relative humidity and wind profile from 950hPa to 200hPa.

=item * C<two> : A two week overview forecast (may be unmaintained).

=back

=back 

Optional parameters (see the API documentation for further details):

=over 4

=item * C<lang> : Default is C<en>, also supports C<zh-CN> or C<zh-TW>.

=item * C<unit> : C<metric> (default) or C<british> units.

=item * C<output> : Output format, supports C<json> (default), C<xml> or C<png>.

=item * C<tzshift> : Timezone offset in hours (-23 to 23).

=item * C<ac> : Altitude correction (e.g. temp) for high peaks. Default C<0>, accepts
C<2> or C<7> (in km). Only for C<astro> product.

=back

=head2 C<get_response>

    my $response = $w7t->get_response(
        lat     => $lat,
        lon     => $lon,
        product => $product
        %args?
    );

Same as C<get> except it returns the full L<HTTP::Response> from the API (so you
can handle bad requests yourself).


=head1 CONVENIENCE FUNCTIONS

=head2 C<products>

    my @products = Weather::Astro7Timer::products();

Returns the supported forecast products.

=cut

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(%args);
}

sub get {
    my $self = shift;
    my %args = @_;
    $args{lang}   ||= 'en';
    $args{output} ||= 'json';
    $args{output} = 'internal' if $args{output} eq 'png';
    $self->{output} = $args{output};

    return $self->_get_output($self->get_response(%args), wantarray);
}

sub get_response {
    my $self = shift;
    my %args = @_;

    croak("product was not defined")
        unless $args{product};

    croak("product not supported")
        unless grep { /^$args{product}$/ } products();

    Weather::API::Base::_verify_lat_lon(\%args);

    return $self->_get_ua($self->_weather_url(%args));
}

sub _weather_url {
    my $self = shift;
    my %args = @_;
    my $prod = delete $args{product};
    my $url  = "www.7timer.info/bin/$prod.php?"
        . join("&", map {"$_=$args{$_}"} keys %args);

    return $url;
}

sub products {
    return qw/astro two civil civillight meteo/;
}

=head1 HELPER FUNCTIONS

=head2 C<init_to_ts>

    my $timestamp = Weather::Astro7Timer::init_to_ts($report{init});

Returns a unix timestamp from the init date. For the subsequent entries of the
timeseries you can add C<timepoint> * 3600 to the timestamp.

=cut

sub init_to_ts {
    my $init = shift;

    return unless $init =~ /^(\d{4})(\d\d)(\d\d)(\d\d)$/;
    return timegm(0,0,$4,$3,$2-1,$1) 
}

=head1 HELPER FUNCTIONS FROM Weather::API::Base

The parent class L<Weather::API::Base> contains some useful functions:

  use Weather::API::Base qw(:all);

  # Get time in YYYY-MM-DD HH:mm:ss format, local time zone
  my $datetime = ts_to_date(time());

  # Convert 30 degrees Celsius to Fahrenheit
  my $result = convert_units('C', 'F', 30);

See the doc for that module for more details.

=head1 OTHER PERL WEATHER MODULES

A quick listing of Perl modules for current weather and forecasts from various sources:

=head2 L<Weather::OWM>

OpenWeatherMap uses various weather sources combined with their own ML and offers
a couple of free endpoints (the v2.5 current weather and 5d/3h forecast) with generous
request limits. Their newer One Call 3.0 API also offers some free usage (1000 calls/day)
and the cost is per call above that. If you want access to history APIs, extended
hourly forecasts etc, there are monthly subscriptions. L<Weather::OWM> is from the
same author as this module and similar in use.

=head2 L<Weather::WeatherKit>

An alternative source for multi-source forecasts is Apple's WeatherKit (based on
the old Dark Sky weather API). It offers 500k calls/day for free, but requires a
paid Apple developer account. You can use L<Weather::WeatherKit>, which is very
similar to this module (same author).

=head2 L<Weather::YR>

The Norwegian Meteorological Institute offers the free YR.no service (no registration
needed), which can be accessed via L<Weather::YR>. I am not affiliated with that module.

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/dkechag/Weather-Astro7Timer> (preferred), or on RT (via the email
C<bug-weather-astro7timer at rt.cpan.org> or L<web interface|https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Astro7TImer>).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/dkechag/Weather-Astro7Timer>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
