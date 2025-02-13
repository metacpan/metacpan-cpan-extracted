package TimeZone::TimeZoneDB;

use strict;
use warnings;

use Carp;
use CHI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Time::HiRes;
use URI;

=head1 NAME

TimeZone::TimeZoneDB - Interface to L<https://timezonedb.com> for looking up Timezone data

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use TimeZone::TimeZoneDB;

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
    my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

=head1 DESCRIPTION

The C<TimeZone::TimeZoneDB> Perl module provides an interface to the L<https://timezonedb.com> API,
enabling users to retrieve timezone data based on geographic coordinates.
It supports configurable HTTP user agents, allowing for proxy settings and request throttling.
The module includes robust error handling, ensuring proper validation of input parameters and secure API interactions.
JSON responses are safely parsed with error handling to prevent crashes.
Designed for flexibility,
it allows users to override default configurations while maintaining a lightweight and efficient structure for querying timezone information.

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

    my $tzdb = TimeZone::TimeZoneDB->new();
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    my $tz = $tzdb->tz({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate's time zone is $tz.\n";

=cut

sub new
{
	my($class, %args) = @_;

	if(!defined($class)) {
		# TimeZone::TimeZoneDB::new() used rather than TimeZone::TimeZoneDB->new()
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $key = $args{'key'} or Carp::croak("'key' argument is required");

	my $ua = $args{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	my $host = $args{host} || 'api.timezonedb.com';

	# Set up caching (default to an in-memory cache if none provided)
	my $cache = $args{cache} || CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 day',
	);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	my $min_interval = $args{min_interval} || 0;	# default: no delay

	return bless {
		key => $key,
		ua => $ua,
		host => $host,
		cache => $cache,
		min_interval => $min_interval,
		last_request => 0,	# Initialize last_request timestamp
		%args,
	}, $class;
}

=head2 get_time_zone

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Find Ramsgate's time zone
    $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'}, "\n";

=cut

sub get_time_zone
{
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif((@_ == 1) && ref($_[0]) && $_[0]->can('latitude')) {
		my $location = $_[0];
		$param{latitude} = $location->latitude();
		$param{longitude} = $location->longitude();
	} elsif((@_ % 2) == 0) {
		%param = @_;
	} else {
		Carp::carp('Usage: get_time_zone(latitude => $latitude, longitude => $longitude)');
		return;
	}

	my $latitude = $param{latitude};
	my $longitude = $param{longitude};

	if((!defined($latitude)) || (!defined($longitude))) {
		Carp::carp('Usage: get_time_zone(latitude => $latitude, longitude => $longitude)');
		return;
	}

	my $uri = URI->new("https://$self->{host}/v2.1/get-time-zone");

	# Note - we have to pass in the key in the URL, as the API doesn't support the Authorization header
	$uri->query_form(
		by => 'position',
		lat => $latitude,
		lng => $longitude,
		format => 'json',
		key => $self->{'key'}
	);
	my $url = $uri->as_string();

	# # Set up HTTP headers
	# my $req = HTTP::Request->new(GET => $url);
	# $req->header('Authorization' => "Bearer $self->{key}");

	# $url =~ s/%2C/,/g;

	# Create a cache key based on the location (might want to use a stronger hash function if needed)
	my $cache_key = "tz:$latitude:$longitude";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	my $res = $self->{ua}->get($url);
	# my $res = $self->{ua}->request($req);

	# Update last_request timestamp
	$self->{last_request} = time();

	if($res->is_error()) {
		Carp::croak("$url API returned error: ", $res->status_line());
		return;
	}
	# $res->content_type('text/plain');	# May be needed to decode correctly

	my $rc;
	eval { $rc = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content()) };
	if($@) {
		Carp::carp("Failed to parse JSON response: $@");
		return;
	}

	# Cache the result before returning it
	$self->{cache}->set($cache_key, $rc);

	if($rc && defined($rc->{'status'}) && ($rc->{'status'} ne 'OK')) {
		# TODO: print error code
		return;
	}
	return $rc;	# No support for list context, yet

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $tzdb->ua()->env_proxy(1);

Free accounts are limited to one search a second,
so you can use L<LWP::UserAgent::Throttled> to keep within that limit.

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('timezonedb.com' => 1);
    $tzdb->ua($ua);

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head1 AUTHOR

Nigel Horne, C<< <njh@bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at L<https://timezonedb.com>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-timezone-timezonedb at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

TimezoneDB API: L<https://timezonedb.com/api>

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
