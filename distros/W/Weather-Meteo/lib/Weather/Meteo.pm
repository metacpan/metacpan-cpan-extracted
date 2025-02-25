package Weather::Meteo;

use strict;
use warnings;

use Carp;
use CHI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Scalar::Util;
use Time::HiRes;
use URI;

use constant FIRST_YEAR => 1940;

=head1 NAME

Weather::Meteo - Interface to L<https://open-meteo.com> for historical weather data

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

The C<Weather::Meteo> module provides an interface to the Open-Meteo API for retrieving historical weather data from 1940.
It allows users to fetch weather information by specifying latitude, longitude, and a date.
The module supports object-oriented usage and allows customization of the HTTP user agent.

      use Weather::Meteo;

      my $meteo = Weather::Meteo->new();
      my $weather = $meteo->weather({ latitude => 0.1, longitude => 0.2, date => '2022-12-25' });

=over 4

=item * Caching

Identical requests are cached (using L<CHI> or a user-supplied caching object),
reducing the number of HTTP requests to the API and speeding up repeated queries.

This module leverages L<CHI> for caching geocoding responses.
When a geocode request is made,
a cache key is constructed from the request.
If a cached response exists,
it is returned immediately,
avoiding unnecessary API calls.

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API
calls can be specified via the C<min_interval> parameter in the constructor.
Before making an API call,
the module checks how much time has elapsed since the
last request and,
if necessary,
sleeps for the remaining time.

=back

=head1 METHODS

=head2 new

    my $meteo = Weather::Meteo->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $meteo = Weather::Meteo->new(ua => $ua);

    my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
    my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

Creates a new instance. Acceptable options include:

=over 4

=item * C<cache>

A caching object.
If not provided,
an in-memory cache is created with a default expiration of one hour.

=item * C<host>

The API host endpoint.
Defaults to L<https://archive-api.open-meteo.com>.

=item * C<min_interval>

Minimum number of seconds to wait between API requests.
Defaults to C<0> (no delay).
Use this option to enforce rate-limiting.

=item * C<ua>

An object to use for HTTP requests.
If not provided, a default user agent is created.

=back

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Weather::Meteo::new() used rather than Weather::Meteo->new()
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $ua = $args{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	my $host = $args{host} || 'archive-api.open-meteo.com';

	# Set up caching (default to an in-memory cache if none provided)
	my $cache = $args{cache} || CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 day',
	);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	my $min_interval = $args{min_interval} || 0;	# default: no delay

	return bless {
		min_interval => $min_interval,
		last_request => 0,	# Initialize last_request timestamp
		%args,
		cache => $cache,
		host => $host,
		ua => $ua
	}, $class;
}

=head2 weather

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Print snowfall at 1AM on Christmas morning in Ramsgate
    $weather = $meteo->weather($ramsgate, '2022-12-25');
    @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

    use DateTime;
    my $dt = DateTime->new(year => 2024, month => 2, day => 1);
    $weather = $meteo->weather({ location => $ramsgate, date => $dt });

The date argument can be an ISO-8601 formatted date,
or an object that understands the strftime method.

Takes an optional argument, tz, containing the time zone.
If not given, the module tries to work it out from the given location,
for that to work set TIMEZONEDB_KEY to be your API key from L<https://timezonedb.com>.
If all else fails, the module falls back to Europe/London.

=cut

sub weather
{
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif((scalar(@_) == 2) && Scalar::Util::blessed($_[0]) && ($_[0]->can('latitude'))) {
		# Two arguments - a location object and a date
		my $location = $_[0];
		$param{latitude} = $location->latitude();
		$param{longitude} = $location->longitude();
		$param{'date'} = $_[1];
		if($_[0]->can('tz') && $ENV{'TIMEZONEDB_KEY'}) {
			$param{'tz'} = $_[0]->tz();
		}
	} elsif(ref($_[0])) {
		Carp::croak('Usage: weather(latitude => $latitude, longitude => $longitude, date => "YYYY-MM-DD" [ , tz = $tz ])');
		return;
	} elsif((@_ % 2) == 0) {
		%param = @_;
	}

	my $latitude = $param{latitude};
	my $longitude = $param{longitude};
	my $location = $param{'location'};
	my $date = $param{'date'};
	my $tz = $param{'tz'} || 'Europe/London';

	if((!defined($latitude)) && defined($location) &&
	   Scalar::Util::blessed($location) && $location->can('latitude')) {
		$latitude = $location->latitude();
		$longitude = $location->longitude();
	}
	if((!defined($latitude)) || (!defined($longitude)) || (!defined($date))) {
		Carp::croak('Usage: weather(latitude => $latitude, longitude => $longitude, date => "YYYY-MM-DD")');
		return;
	}

	# Handle numbers starting with a decimal point
	if($latitude =~ /^\./) {
		$latitude = "0$latitude";
	}
	if($latitude =~ /^\-\.(\d+)$/) {
		$latitude = "-0.$1";
	}
	if($longitude =~ /^\./) {
		$longitude = "0$longitude";
	}
	if($longitude =~ /^\-\.(\d+)$/) {
		$longitude = "-0.$1";
	}

	if(($latitude !~ /^-?\d+(\.\d+)?$/) || ($longitude !~ /^-?\d+(\.\d+)?$/)) {
		Carp::croak(__PACKAGE__, ": Invalid latitude/longitude format ($latitude, $longitude)");
	}

	if(Scalar::Util::blessed($date) && $date->can('strftime')) {
		$date = $date->strftime('%F');
	} elsif($date =~ /^(\d{4})-/) {
		return if($1 < FIRST_YEAR);
	} else {
		Carp::carp("'$date' is not a valid date");
		return;
	}

	unless($date =~ /^\d{4}-\d{2}-\d{2}$/) {
		croak('Invalid date format. Expected YYYY-MM-DD');
	}

	my $uri = URI->new("https://$self->{host}/v1/archive");
	my %query_parameters = (
		'latitude' => $latitude,
		'longitude' => $longitude,
		'start_date' => $date,
		'end_date' => $date,
		'hourly' => 'temperature_2m,rain,snowfall,weathercode',
		'daily' => 'weathercode,temperature_2m_max,temperature_2m_min,rain_sum,snowfall_sum,precipitation_hours,windspeed_10m_max,windgusts_10m_max',
		'timezone' => $tz,
			# https://stackoverflow.com/questions/16086962/how-to-get-a-time-zone-from-a-location-using-latitude-and-longitude-coordinates
		'windspeed_unit' => 'mph',
		'precipitation_unit' => 'inch'
	);

	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	$url =~ s/%2C/,/g;

	# Create a cache key based on the location, date and time zone (might want to use a stronger hash function if needed)
	my $cache_key = "weather:$latitude:$longitude:$date:$tz";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	# Enforce rate-limiting: ensure at least min_interval seconds between requests
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	my $res = $self->{ua}->get($url);

	# Update last_request timestamp
	$self->{last_request} = time();

	if($res->is_error()) {
		Carp::carp(ref($self), ": $url API returned error: ", $res->status_line());
		return;
	}
	# $res->content_type('text/plain');	# May be needed to decode correctly

	my $rc;
	eval { $rc = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content()) };
	if($@) {
		Carp::carp("Failed to parse JSON response: $@");
		return;
	}

	if($rc) {
		if($rc->{'error'}) {
			# TODO: print error code
			return;
		}
		if(defined($rc->{'hourly'})) {
			# Cache the result before returning it
			$self->{'cache'}->set($cache_key, $rc);

			return $rc;	# No support for list context, yet
		}
	}

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $meteo->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    $meteo->ua($ua);

=cut

sub ua {
	my $self = shift;

	if (@_) {
		$self->{ua} = shift;
	}
	return $self->{ua}
}

=head1 AUTHOR

Nigel Horne, C<< <njh@bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at L<https://open-meteo.com>.

=head1 BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-weather-meteo at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

Open Meteo API: L<https://open-meteo.com/en/docs#api_form>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Weather::Meteo

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Weather-Meteo>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Weather-Meteo>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Weather-Meteo>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Weather-Meteo>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
