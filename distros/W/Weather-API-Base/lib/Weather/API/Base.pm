package Weather::API::Base;

use 5.008;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use Time::Local;

use Exporter 'import';

our @EXPORT_OK   = qw(ts_to_date datetime_to_ts convert_units);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Weather::API::Base - Base/util module for Weather API clients

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

  ### Using Helper Functions

  use Weather::API::Base qw(:all);

  # Get time in YYYY-MM-DD HH:mm:ss format, local time zone
  my $datetime = ts_to_date(time());

  # Convert a date to unix timestamp
  my $ts = datetime_to_ts('2024-01-12 13:46:40');

  # Convert 30 degrees Celsius to Fahrenheit
  my $result = convert_units('C', 'F', 30);


  ### Building a Weather API client

  use parent 'Weather::API::Base';
  use Weather::API::Base qw(:all);

  # Constructor
  sub new {
      my ($class, %args) = @_;
      return $class->SUPER::new(%args);
  }

  # Getting an HTTP::Response
  sub get_response {
      my $self = shift;
      my $url  = shift;

      return $self->_get_ua($url);
  }

  # Getting the response contents as a scalar or decoded to a data structure
  sub get {
      my $self = shift;
      my $resp = shift;

      return $self->_get_output($resp, wantarray);
  }

=head1 DESCRIPTION

L<Weather::API::Base> is a base class for simple Perl Weather API clients. Apart
from handling JSON and XML API responses (L<JSON> and L<XML::Simple> required respectivelly),
it offers utility functions for time and unit conversions, specifically useful for
weather-related APIs.

This module was mainly created to streamline maintenance of the L<Weather::OWM>,
L<Weather::Astro7Timer> and L<Weather::WeatherKit> modules by factoring out shared
code. In the unlikely event that you'd like to base your own weather or similar
API wrapper module on it, look at the implementation of those modules for guidance.

=head1 CONSTRUCTOR

=head2 C<new>

    my $base = Weather::API::Base->new(
        timeout => $timeout_sec?,
        agent   => $user_agent_string?,
        ua      => $lwp_ua?,
        error   => $die_or_return?,
        debug   => $debug?,
        output  => $output,
        scheme  => $url_scheme?
    );

Creates a Weather::API::Base object. As explained, you'd normally use a module that
inherits from this, but the base class sets these defaults:

    (
        timeout => 30,
        agent   => "libwww-perl $package/$version",
        error   => 'return',
        output  => 'json',
        scheme  => 'https',
    );

Parameters:

=over 4

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<agent> : Customize the user agent string. Default: C<libwww-perl $package/$version">

=item * C<ua> : Pass your own L<LWP::UserAgent> to customize further. Will override C<agent>.

=item * C<error> : If there is an error response with the main methods, you have the options to C<die> or C<return> it. Default: C<return>.

=item * C<debug> : If debug mode is enabled, API URLs accessed are printed in STDERR when calling C<_get_ua>. Default: C<false>.

=item * C<scheme> : You can use C<http> as an option if it is supported by the API and you have trouble building https support for LWP in your system. Default: C<https>.

=item * C<output> : Output format/mode. C<json/xml> are automatically supported for decoding. Default: C<json>.

=back

=head1 PRIVATE METHODS

These are to be used when subclassing.

=head2 C<_get_output>

    $self->_get_output($response, wantarray);

C<$response> should be an L<HTTP::Response> object, unless C<$self-E<gt>{curl}> is true
in which case it should be a string. On C<wantarray> a Perl hash (or array) will be
returned by decoding a JSON/XML response (if C<$self-E<gt>{output}> is C<json/xml>) or
just the decoded content as a value for the C<data> key otherwise.

=head2 C<_get_ua>

    my $resp = $self->_get_ua($url);

Will either use C<$self-E<gt>{ua}> or create a new one and fetch the C<$url> with it.
If the URL does not contain the scheme, it will be applied from C<$self-E<gt>{scheme}>.


=head1 HELPER FUNCTIONS

Exportable helper/utility functions:

=head2 C<convert_units>

    my $result = convert_units($from, $to, $value);

Can convert from/to various units that are used in weather:

=over 4

=item * B<Wind speed:> kph, mph, m/s, Bft, knot

=item * B<Temp:> K, F, C

=item * B<Rainfall & distance:> mm, in, m, km, mi

=item * B<Pressure:> atm, mbar, mmHg, kPa

=back

Use the above units as string parameters. Example:

  $result = convert_units('atm', 'mmHg', 1); # Will return 760 (mmHg per 1 atm)

If you try to convert between non convertible units, the croak message will list
the valid conversions from the 'from' units. For example C<convert_units('kph', 'mm', 10)>
will croak with the speed units (kph, mph, m/s, Bft, knot) that are available to
convert from kph.

Note that the Beaufort scale (C<Bft>) is an empirical scale commonly used in whole
numbers (converting to a range of +/- 0.5 Bft in other units), but the convert
function will actually give you the approximate floating point value based on an
accepted empirical function.

=head2 C<ts_to_date>

    my $datetime = ts_to_date($timestamp, $utc?);

There are many ways to convert unix timestamps to human readable dates, but for
convenience you can use C<ts_to_date>, which is a very fast function that will
return the format C<YYYY-MM-DD HH:mm:ss> in your local time zone, or
C<YYYY-MM-DD HH:mm:ssZ> in UTC if the second argument is true.

=head2 C<datetime_to_ts>

    my $ts = datetime_to_ts($datetime, $utc?);

Fast function that accepts C<YYYY-MM-DD> or C<YYYY-MM-DD HH:mm:ssZ?> and converts
to a timestamp (for midnight in the former case). Will use local timezone unless
you either pass a true second argument or use datetime with the C<Z> (Zulu time)
suffix. Accepts any date/time divider, so strict ISO with C<T> will work as well.

=cut

my $geocache;

sub new {
    my $class = shift;

    my $self = {};
    bless($self, $class);

    my %args = @_;
    my ($package) = caller;
    $package = __PACKAGE__ if $package eq 'main';
    my $version = $package->VERSION;

    my %defaults = (
        scheme  => 'https',
        timeout => 30,
        agent   => "libwww-perl $package/$version",
        output  => 'json',
        units   => 'metric',
        error   => 'return',
    );
    $args{agent} = $args{ua}->agent() if $args{ua};
    $self->{$_} = $args{$_} || $defaults{$_} for keys %defaults;
    $self->{$_} = $args{$_} for qw/ua debug curl language lang/;

    croak("http or https scheme expected")
        if $self->{scheme} ne 'http' && $self->{scheme} ne 'https';

    return $self;
}

sub ts_to_date {
    my $ts = shift;
    my $gm = shift;
    $gm = $gm ? 'Z' : '';
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        $gm ? gmtime($ts) : localtime($ts);
    $mon++;
    $year += 1900;
    return sprintf "%04d-%02d-%02d %02d:%02d:%02d%s", $year, $mon, $mday,
        $hour, $min, $sec, $gm;
}

sub datetime_to_ts {
    my $date = shift;
    my $gm   = shift;
    return ($7 || $gm)
        ? timegm($6, $5, $4, $3, $2 - 1, $1)
        : timelocal($6, $5, $4, $3, $2 - 1, $1)
        if $date =~
        /(\d{4})-(\d{2})-(\d{2})(?:.(\d{2}):(\d{2}):(\d{2})([Zz])?)?/;

    croak("Unrecognized date format (try 'YYYY-MM-DD' or 'YYYY-MM-DD HH:mm:ss')");
}

sub _verify_lat_lon {
    my $args = shift;

    croak("lat between -90 and 90 expected")
        unless defined $args->{lat} && abs($args->{lat}) <= 90;

    croak("lon between -180 and 180 expected")
        unless defined $args->{lon} && abs($args->{lon}) <= 180;
}

sub _get_output {
    my $self    = shift;
    my $resp    = shift;
    my $wantarr = shift;
    my $output  = $wantarr ? $self->{output} : '';

    return _output($resp, $output) if $self->{curl};
 
    if ($resp->is_success) {
        return _output($resp->decoded_content, $output);
    } else {
        if ($self->{error} && $self->{error} eq 'die') {
            die $resp->status_line;
        } else {
            return $wantarr ? (error => $resp) : "ERROR: ".$resp->status_line;
        }
    }
}

sub _get_ua {
    my $self = shift;
    my $url  = shift;
    $url = $self->{scheme}.'://'.$url unless $url =~ /^https?:/;

    warn "$url\n" if $self->{debug};

    $self->_ua unless $self->{ua};

    return $self->{ua}->get($url);
}

sub _ua {
    my $self = shift;

    $self->{ua} = LWP::UserAgent->new();
    $self->{ua}->agent($self->{agent});
    $self->{ua}->timeout($self->{timeout});
}

sub _output {
    my $str    = shift;
    my $format = shift;

    return $str unless $format;

    if ($format eq 'json') {
        require JSON;
        return _deref(JSON::decode_json($str));
    } elsif ($format eq 'xml') {
        require XML::Simple;
        return _deref(XML::Simple::XMLin($str));
    }
    return (data => $str);
}

sub _deref {
    my $ref = shift;
    die "Could not decode response body" unless $ref;
    return $ref unless ref($ref);
    return %$ref if ref($ref) eq 'HASH';
    return @$ref;
}

my %units = (
    kph   => [1000 / 3600,     'm/s'],
    mph   => [1609.344 / 3600, 'm/s'],
    Bft   => [\&_beaufort,     'm/s'],
    knot  => [0.514444,        'm/s'],
    'm/s' => [1,               'm/s'],
    in    => [0.0254,          'm'],
    mm    => [0.001,           'm'],
    mi    => [1609.344,        'm'],
    m     => [1,               'm'],
    km    => [1000,            'm'],
    atm   => [1,               'atm'],
    mbar  => [1/1013.25,       'atm'],
    mmHg  => [1/760,           'atm'],
    kPa   => [1/101.325,       'atm'],
    K     => [\&_kelvin,       'C'],
    F     => [\&_fahr,         'C'],
    C     => [1,               'C'],
);

sub _units {
    my $conv = shift;
    my @list = sort {$units{$b} cmp $units{$a} || $a cmp $b} keys %units;
    return join(', ', @list) unless $conv;
    my @ok = map {($units{$_}->[1] && $units{$_}->[1] ne $_) ? $_ : ()} @list;
    return join(', ', @ok);
}

sub convert_units {
    my ($from, $to, $val) = @_;

    croak "Value not defined." unless defined $val;

    foreach ($from, $to) {
        croak "$_ not recognized. Supported units: "._units unless $units{$_};
    }

    croak "Cannot convert to $to. Can only convert $from to: "._units($from)
        unless $units{$from}->[1] eq $units{$to}->[1];

    $val =
        ref($units{$from}->[0])
        ? $units{$from}->[0]->($val)
        : $val * $units{$from}->[0];

    return $val if $units{$from}->[1] eq $to;

    return
        ref($units{$to}->[0])
        ? $units{$to}->[0]->($val, 1)
        : $val / $units{$to}->[0];
}

sub _kelvin {
    my $val  = shift;
    my $mult = shift() ? 1 : -1;

    return $val + $mult * 273.15;
}

sub _fahr {
    my $val = shift;
    my $rev = shift;

    return $val * 9 / 5 + 32 if $rev;
    return ($val - 32) * 5 / 9;
}

sub _beaufort {
    my $val = shift;
    my $rev = shift;

    return ($val / 0.836)**(2 / 3) if $rev;
    return 0.836 * ($val**1.5);
}

=head1 RELATED WEATHER MODULES

A quick listing of Perl modules that are based on L<Weather::API::Base>:

=head2 L<Weather::Astro7Timer>

If you are interested in astronomy/stargazing the 7Timer! weather forecast might be
very useful. It uses the standard NOAA forecast, but calculates astronomical seeing
and transparency. It is completely free, no API key needed.

=head2 L<Weather::OWM>

OpenWeatherMap uses various weather sources combined with their own ML and offers
a couple of free endpoints (the v2.5 current weather and 5d/3h forecast) with generous
request limits. Their newer One Call 3.0 API also offers some free usage (1000 calls/day)
and the cost is per call above that. If you want access to history APIs, extended
hourly forecasts etc, there are monthly subscriptions.

=head2 L<Weather::WeatherKit>

An alternative source for multi-source forecasts is Apple's WeatherKit (based on
the old Dark Sky weather API). It offers 500k calls/day for free, but requires a
paid Apple developer account.

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on L<GitHub|https://github.com/dkechag/Weather-API-Base>.

=head1 GIT

L<https://github.com/dkechag/Weather-API-Base>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
