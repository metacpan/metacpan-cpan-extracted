package Weather::Meteo;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS;
use LWP::UserAgent;
use Scalar::Util;
use URI;

use constant FIRST_YEAR => 1940;

=head1 NAME

Weather::Meteo - Interface to L<https://open-meteo.com> for historical weather data

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

The C<Weather::Meteo> module provides an interface to the Open-Meteo API for retrieving historical weather data from 1940.
It allows users to fetch weather information by specifying latitude, longitude, and a date.
The module supports object-oriented usage and allows customization of the HTTP user agent.

      use Weather::Meteo;

      my $meteo = Weather::Meteo->new();
      my $weather = $meteo->weather({ latitude => 0.1, longitude => 0.2, date => '2022-12-25' });

=head1 METHODS

=head2 new

    my $meteo = Weather::Meteo->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $meteo = Weather::Meteo->new(ua => $ua);

    my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
    my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

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

	return bless { ua => $ua, host => $host }, $class;
}

=head2 weather

    use Geo::Location::Point;

The date argument can be an ISO-8601 formatted date,
or an object that understands the strftime method.

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Print snowfall at 1AM on Christmas morning in Ramsgate
    $weather = $meteo->weather($ramsgate, '2022-12-25');
    @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

    use DateTime;
    my $dt = DateTime->new(year => 2024, month => 2, day => 1);
    $weather = $meteo->weather({ location => $ramsgate, date => $dt });

Takes an optional argument, tz, which defaults to 'Europe/London'.
For that to work set TIMEZONEDB_KEY to be your API key from L<https://timezonedb.com>.

=cut

sub weather
{
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif((@_ == 2) && Scalar::Util::blessed($_[0]) && ($_[0]->can('latitude'))) {
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
	if((!defined($latitude)) || (!defined($longitude))) {
		Carp::croak('Usage: weather(latitude => $latitude, longitude => $longitude, date => "YYYY-MM-DD")');
		return;
	}

	if(($latitude !~ /^-?\d+(\.\d+)?$/) || ($longitude !~ /^-?\d+(\.\d+)?$/)) {
		Carp::croak(__PACKAGE__, ': Invalid latitude/longitude format');
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

	my $res = $self->{ua}->get($url);

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
