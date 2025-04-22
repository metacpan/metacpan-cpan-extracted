package WebService::OpenSky;

# ABSTRACT: Perl interface to the OpenSky Network API

# see also https://github.com/openskynetwork/opensky-api
use v5.20.0;
use WebService::OpenSky::Moose;
use WebService::OpenSky::Types qw(
  ArrayRef
  Bool
  Dict
  HashRef
  InstanceOf
  Int
  Latitude
  Longitude
  NonEmptyStr
  Num
  Optional
  Undef
);
use WebService::OpenSky::Response::States;
use WebService::OpenSky::Response::Flights;
use WebService::OpenSky::Response::FlightTrack;
use PerlX::Maybe;
use Config::INI::Reader;

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw( decode_json );
use Type::Params -sigs;

our $VERSION = '0.5';

param config => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => method() { $ENV{HOME} . '/.openskyrc' },
);

param [qw/debug raw testing/] => (
    isa     => Bool,
    default => 0,
);

field _config_data => (
    isa     => HashRef,
    default => method() {
        my $file = $self->config // '';
        if ( !-e $file ) {
            if ($self->testing                                            # if we're testing
                || ( $self->_has_username   && $self->_has_password )     # or we have a username and password
                || ( $ENV{OPENSKY_USERNAME} && $ENV{OPENSKY_PASSWORD} )
              )                                                           # even if they're from %ENV
            {
                return {};                                                # then we don't need a config file
            }
            croak("Config file '$file' does not exist");
        }
        Config::INI::Reader->read_file( $self->config );
    },
);

field _last_request_time => (
    isa     => HashRef [Int],
    default => method() {
        return {
            '/states/all' => 0,
            '/states/own' => 0,
        };
    }
);

field _ua => (
    isa     => InstanceOf ['Mojo::UserAgent'],
    default => method() { Mojo::UserAgent->new },
);

param _username => (
    isa       => NonEmptyStr,
    lazy      => 1,
    init_arg  => 'username',
    predicate => '_has_username',
    default   => method() { $ENV{OPENSKY_USERNAME} // $self->_config_data->{opensky}{username} },
);

param _password => (
    isa       => NonEmptyStr,
    lazy      => 1,
    init_arg  => 'password',
    predicate => '_has_password',
    default   => method() { $ENV{OPENSKY_PASSWORD} // $self->_config_data->{opensky}{password} },
);

param _base_url => (
    init_arg => 'base_url',
    isa      => NonEmptyStr,
    lazy     => 1,
    default  => method() {
        $self->_config_data->{_}{base_url} // 'https://opensky-network.org/api';
    },
);

field limit_remaining => (
    isa     => Int | Undef,
    writer  => '_set_limit_remaining',
    default => undef,
);

signature_for get_states => (
    method => 1,
    named  => [
        time   => Optional [Num], { default => 0 },
        icao24 => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
        bbox   => Optional [
            Dict [
                lamin => Latitude,
                lomin => Longitude,
                lamax => Latitude,
                lomax => Longitude,
            ],
        ],
        { default => {} },
        extended => Optional [Bool],
    ],
    named_to_list => 1,
);

method get_states( $seconds, $icao24, $bbox, $extended ) {
    my %params = (
        maybe time     => $seconds,
        maybe icao24   => $icao24,
        maybe extended => $extended,
    );
    if ( keys $bbox->%* ) {
        $params{$_} = $bbox->{$_} for qw( lamin lomin lamax lomax );
    }

    return $self->_get_response(
        route  => '/states/all',
        params => \%params,
        class  => 'WebService::OpenSky::Response::States',

        # rate_limit_noauth => 10,
        # rate_limit_auth => 5,
    );
}

signature_for get_my_states => (
    method => 1,
    named  => [
        time    => Optional [Num], { default => 0 },
        icao24  => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
        serials => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
    ],
    named_to_list => 1,
);

method get_my_states( $seconds, $icao24, $serials ) {
    my %params = (
        extended      => 1,
        maybe time    => $seconds,
        maybe icao24  => $icao24,
        maybe serials => $serials,
    );
    return $self->_get_response(
        route  => '/states/own',
        params => \%params,
        class  => 'WebService::OpenSky::Response::States',

        # rate_limit_noauth => undef,
        # rate_limit_auth => 1,
    );
}

method get_flights_from_interval( $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 7200 ) {
        croak 'The time interval must be smaller than two hours.';
    }

    my %params = ( begin => $begin, end => $end );
    return $self->_get_response(
        route  => '/flights/all',
        params => \%params,
        class  => 'WebService::OpenSky::Response::Flights',
    );
}

method get_flights_by_aircraft( $icao24, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 2592 * 1e3 ) {
        croak 'The time interval must be smaller than 30 days.';
    }

    my %params = ( icao24 => $icao24, begin => $begin, end => $end );
    return $self->_get_response(
        route  => '/flights/aircraft',
        params => \%params,
        class  => 'WebService::OpenSky::Response::Flights',
    );
}

method get_arrivals_by_airport( $airport, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 604800 ) {
        croak 'The time interval must be smaller than 7 days.';
    }

    my %params = ( airport => $airport, begin => $begin, end => $end );
    return $self->_get_response(
        route  => '/flights/arrival',
        params => \%params,
        class  => 'WebService::OpenSky::Response::Flights',
    );
}

method get_departures_by_airport( $airport, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 604800 ) {
        croak 'The time interval must be smaller than 7 days.';
    }

    my %params = ( airport => $airport, begin => $begin, end => $end );
    return $self->_get_response(
        route  => '/flights/departure',
        params => \%params,
        class  => 'WebService::OpenSky::Response::Flights',
    );
}

method get_track_by_aircraft( $icao24, $time ) {
    if ( $time != 0 && ( time - $time ) > 2592 * 1e3 ) {
        croak 'It is not possible to access flight tracks from more than 30 days in the past.';
    }

    my %params = ( icao24 => $icao24, time => $time );
    return $self->_get_response(
        route  => '/tracks/all',
        params => \%params,
        class  => 'WebService::OpenSky::Response::FlightTrack',
    );
}

signature_for _get_response => (
    method => 1,
    named  => [
        route            => NonEmptyStr,
        params           => Optional [HashRef],
        credits          => Optional [Bool],
        class            => Optional [NonEmptyStr],
        no_auth_required => Optional [Bool],
    ],
    named_to_list => 1,
);

method _get_response( $route, $params, $credits, $response_class, $no_auth_required ) {
    my $url = $self->_url( $route, $params, $no_auth_required );

    if ( !$self->testing ) {

        # XXX Ugh. I'd like to use attributes to attach metadata to the
        # methods, but with the attribute order switch, I can't. So I'm
        # going to leave this ugly hack here.
        my $method
          = $route eq '/states/all' ? 'get_states'
          : $route eq '/states/own' ? 'get_my_states'
          :                           undef;
        if ($method) {
            if ( my $delay_remaining = $self->delay_remaining($method) ) {
                carp("You have to wait $delay_remaining seconds before you can call $method again.");
                return;
            }
        }

        my $limit_remaining = $self->limit_remaining;

        # if it's not defined, we haven't made an API call yet
        if ( defined $limit_remaining && !$limit_remaining ) {
            carp("You have no API credits left for $route. See https://openskynetwork.github.io/opensky-api/rest.html#limitations");
            return;
        }
    }

    my $response  = $self->_GET($url);
    my $remaining = $response->headers->header('X-Rate-Limit-Remaining');

    $self->_debug( $response->headers->to_string . "\n" );

    # not all requests cost credits, so we only want to set the limit if
    # $remaining is defined
    $self->_set_limit_remaining($remaining) if !$credits && defined $remaining;

    # this is annoying. If the didn't match any criteria, the service should return a 200
    # and an empty response. Instead, we get a 404.
    if ( !$response->is_success && $response->code != 404 ) {
        croak $response->to_string;
    }
    $self->_last_request_time->{$route} = time;

    return $remaining if $credits;
    my $response_body = $response->body;
    if ( $self->debug ) {
        $self->_debug($response_body);
    }
    my $raw_response = $response_body ? decode_json($response_body) : undef;
    return $response_class->new(
        route              => $route,
        query              => $params,
        maybe raw_response => $raw_response,
    );
}

method delay_remaining($method) {
    state $rate_limits = {
        'get_states' => {
            route  => '/states/all',
            noauth => 10,
            auth   => 5,
        },
        'get_my_states' => {
            route  => '/states/own',
            noauth => undef,
            auth   => 1,
        },
    };
    my $delay = $rate_limits->{$method} or return 0;
    my $limit = $self->limit_remaining;

    # XXX this is a bit of a hack. If we've not made any requests yet, we don't
    # know what the limit is, so we assume they haven't made a request yet.
    # Probably need to revisit this. I would love an API endpoint that lets me
    # fetch the limit
    return 0 if !defined $limit;

    return 0 if $limit <= 0;
    my $seconds_since_last_request = time - $self->_last_request_time->{ $delay->{route} };

    my $delay_remaining;
    if ( !$self->_password && $delay->{noauth} ) {
        $delay = $delay->{noauth} - $seconds_since_last_request;
    }
    else {
        $delay_remaining = $delay->{auth} - $seconds_since_last_request;
    }
    return $delay_remaining > 0 ? $delay_remaining : 0;
}

# an easy target to override for testing
method _GET($url) {
    $self->_debug("GET $url\n");
    return $self->_ua->get($url)->res;
}

method _debug($msg) {
    return if !$self->debug;
    say STDERR $msg;
}

method _url( $url, $params = {}, $no_auth_required = 0 ) {
    my $username = $self->_username;
    my $password = $self->_password;
    if ( ( !$username || !$password ) && $no_auth_required ) {
        return Mojo::URL->new( $self->_base_url . $url )->query($params);
    }
    $url = Mojo::URL->new( $self->_base_url . $url )->userinfo( $self->_username . ':' . $self->_password );
    $url->query($params);
    return $url;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky - Perl interface to the OpenSky Network API

=head1 VERSION

version 0.5

=head1 SYNOPSIS

    use WebService::OpenSky;

    my $api = WebService::OpenSky->new(
        username => 'username',
        password => 'password',
    );

    my $states = $api->get_states;
    while ( my $vector = $states->next ) {
        say $vector->callsign;
    }

=head1 DESCRIPTION

This is a Perl interface to the OpenSky Network API. It provides a simple, object-oriented
interface, but also allows you to fetch raw results for performance.

This is largely based on L<the official Python
implementation|https://github.com/openskynetwork/opensky-api/blob/master/python/opensky_api.py>,
but with some changes to make it more user-friendly for Perl developers.

=head1 CONSTRUCTOR

Basic usage:

    my $open_sky = WebService::OpenSky->new;

This will create an instance of the API object with no authentication. This only allows you access
to the C<get_states> method.

If you want to use the other methods, you will need to provide a username and password:

    my $open_sky = WebService::OpenSky->new(
        username => 'username',
        password => 'password',
    );

You can get a username and password by registering for a free account on
L<OpenSky Network|https://opensky-network.org>.

Alternatively, you can set the C<OPENSKY_USERNAME> and C<OPENSKY_PASSWORD>
environment variables, or create a C<.openskyrc> file in your home directory
with the following contents:

    [opensky]
    username = myusername
    password = s3cr3t

If you'd like that file in another directory, just pass the C<config> argument:

    my $open_sky = WebService::OpenSky->new(
        config => '/path/to/config',
    );

All methods return objects. However, we don't inflate the results into objects
until you ask for the next result. This is to avoid inflating all results if it's expensive.
In that case, you can ask for the raw results:

    my $open_sky = WebService::OpenSky->new->get_states;
    my $raw = $open_sky->raw_response;

If you are debugging why something failed, pass the C<debug> attribute to see
a C<STDERR> trace of the requests and responses:

    my $open_sky = WebService::OpenSky->new(
        debug => 1,
    );

In the unlikely event that you need to change the base URL, you can do so:

	my $open_sky = WebService::OpenSky->new(
		base_url => 'https://opensky-network.org/api/v2',
	);

The base url defaults to L<https://opensky-network.org/api>.

=head1 METHODS

For more insight to all methods, see L<the OpenSky API
documentation|https://openskynetwork.github.io/opensky-api/>.

Note a key difference between the Python implementation and this one: the
Python implementation returns <None> if results are not found. For this
module, you will still receive the iterator, but it won't have any results.
This allows you to keep a consistent interface without having to check for
C<undef> everywhere.

=head2 get_states

    my $states = $api->get_states;

Returns an instance of L<WebService::OpenSky::Response::States>.

This API call can be used to retrieve any state vector of the OpenSky. Please
note that rate limits apply for this call. For API calls without rate
limitation, see C<get_my_states>.

By default, the above fetches all current state vectors.

You can (optionally) request state vectors for particular airplanes or times
using the following request parameters:

    my $states = $api->get_states(
        icao24 => 'abc9f3',
        time   => 1517258400,
    );

Both parameters are optional.

=over 4

=item * C<icao24>

One or more ICAO24 transponder addresses represented by a hex string (e.g.
abc9f3). To filter multiple ICAO24 append the property once for each address.
If omitted, the state vectors of all aircraft are returned.

=item * C<time>

A Unix timestamp (seconds since epoch). Only state vectors after this timestamp are returned.

=back

In addition to that, it is possible to query a certain area defined by a
bounding box of WGS84 coordinates. For this purpose, add the following
parameters:

    my $states = $api->get_states(
        bbox => {
            lomin => -0.5,     # lower bound for the longitude in decimal degrees
            lamin => 51.25,    # lower bound for the latitude in decimal degrees
            lomax => 0,        # upper bound for the longitude in decimal degrees
            lamax => 51.75,    # upper bound for the latitude in decimal degrees
        },
    );

You can also request the category of aircraft by adding the following request parameter:

    my $states = $api->get_states(
        extended => 1,
    );

Any and all of the above parameters can be combined.

    my $states = $api->get_states(
        icao24   => 'abc9f3',
        time     => 1517258400,
        bbox     => {
            lomin => -0.5,     # lower bound for the longitude in decimal degrees
            lamin => 51.25,    # lower bound for the latitude in decimal degrees
            lomax => 0,        # upper bound for the longitude in decimal degrees
            lamax => 51.75,    # upper bound for the latitude in decimal degrees
        },
        extended => 1,
    );

=head2 get_my_states

    my $states = $api->get_my_states;

Returns an instance of L<WebService::OpenSky::Response::States>.

This API call can be used to retrieve state vectors for your own sensors
without rate limitations. Note that authentication is required for this
operation, otherwise you will get a 403 - Forbidden.

By default, the above fetches all current state vectors for your states.
However, you can also pass arguments to fine-tune this:

    my $states = $api->get_my_states(
        time    => 1517258400,
        icao24  => 'abc9f3',
        serials => [ 1234, 5678 ],
    );

=over 4

=item * C<time>

The time in seconds since epoch (Unix timestamp to retrieve states for.
Current time will be used if omitted.

=item * <icao24>

One or more ICAO24 transponder addresses represented by a hex string (e.g.
abc9f3). To filter multiple ICAO24 append the property once for each address.
If omitted, the state vectors of all aircraft are returned.

=item * C<serials>

Retrieve only states of a subset of your receivers. You can pass this argument
several time to filter state of more than one of your receivers. In this case,
the API returns all states of aircraft that are visible to at least one of the
given receivers.

=back

=head2 C<get_arrivals_by_airport>

    my $arrivals = $api->get_arrivals_by_airport('KJFK', $start, $end);

Returns an instance of L<WebService::OpenSky::Response::Flights>.

Positional arguments:

=over 4

=item * C<airport>

The ICAO code of the airport you want to get arrivals for.

=item * C<start>

The start time in seconds since epoch (Unix timestamp).

=item * C<end>

The end time in seconds since epoch (Unix timestamp).

=back

The interval between start and end time must be smaller than seven days.

=head2 C<get_departures_by_airport>

Identical to C<get_arrivals_by_airport>, but returns departures instead of arrivals.

=head2 C<get_flights_by_aircraft>

    my $flights = $api->get_flights_by_aircraft($icao24, $start, $end);

Returns an instance of L<WebService::OpenSky::Response::Flights>.

The first argument is the lower-case ICAO24 transponder address of the aircraft you want.

The second and third arguments are the start and end times in seconds since
epoch (Unix timestamp). Their interval must be equal to or less than 30 days.

=head2 C<get_flights_from_interval>

    my $flights = $api->get_flights_from_interval($start, $end);

Returns an instance of L<WebService::OpenSky::Response::Flights>.

=head2 C<get_track_by_aircraft>

	my $track = $api->get_track_by_aircraft( $icao24, $start );

Adds support for the experimental L<GET
/tracks|https://openskynetwork.github.io/opensky-api/rest.html#track-by-aircraft>
endpoint. Returns an instance of
L<WebService::OpenSky::Response::FlightTrack>.

Per the OpenSky documentation, this endpoint is experimental and may be removed or simply
not working at any time.

=head2 C<limit_remaining>

    my $limit = $api->limit_remaining;

Returns the number of API credits you have left. See
L<https://openskynetwork.github.io/opensky-api/rest.html#limitations> for more
information.

If you have not yet made a request, this method will return C<undef>.

=head2 C<delay_remaining($method)>

	my $delay = $api->delay_remaining('get_states');

When you call either C<get_states> or C<get_my_states>, the your calls will
be rate limited. This method returns the number of seconds you have to wait
until you can make another request. You can C<sleep> that many seconds before making
a new call:

	sleep $api->delay_remaining('get_states');

If you attempt to make a request before the delay has expired, you will get a warning and
no request will be made.

See
L<limitations|https://openskynetwork.github.io/opensky-api/rest.html#limitations>
for more details.

=head1 EXAMPLES

Perl Wikipedia, L<OpenSky Network|https://en.wikipedia.org/wiki/OpenSky_Network> is ...

    The OpenSky Network is a non-profit association based in Switzerland that
    provides open access of flight tracking control data. It was set up as
    a research project by several universities and government entities with
    the goal to improve the security, reliability and efficiency of the
    airspace. Its main function is to collect, process and store air traffic
    control data and provide open access to this data to the public. Similar
    to many existing flight trackers such as Flightradar24 and FlightAware,
    the OpenSky Network consists of a multitude of sensors (currently around
    1000, mostly concentrated in Europe and the US), which are connected to
    the Internet by volunteers, industrial supporters, academic, and
    governmental organizations. All collected raw data is archived in a
    large historical database, containing over 23 trillion air traffic control
    messages (November 2020). The database is primarily used by researchers
    from different areas to analyze and improve air traffic control
    technologies and processes

=head2 Elon Musk's Jet

However, this data can be used to track the movements of certain aircraft. For
example, Elon Musk's primary private jet (he has three, but this is the one he
mainly uses), has the ICAO24 transponder address C<a835af>. Running the
following code ...

    use WebService::OpenSky;

    my $musks_jet = 'a835af';
    my $openapi   = WebService::OpenSky->new;

    my $days = shift @ARGV // 7;
    my $now  = time;
    my $then = $now - 86400 * $days;    # Max 30 days

    my $flight_data = $openapi->get_flights_by_aircraft( $musks_jet, $then, $now );
    say "Jet $musks_jet has " . $flight_data->count . " flights";

As of this writing, that prints out:

    Jet a835af has 6 flights

=head1 ETHICS

There are some ethical considerations to be made when using this module. I was
ambivalent about writing it, but I decided to do so because I think it's
important to be aware of the privacy implications. However, it's also
important to be aware of the L<climate
implications|https://www.euronews.com/green/2023/03/30/wasteful-luxury-private-jet-pollution-more-than-doubles-in-europe>.

Others are using the OpenSky API to model the amount of carbon being released
by the aviation industry, while others have used this public data to predict
corporate mergers and acquisitions. There are a wealth of reasons why this
data is useful, but not all of those reasons are good. Be good.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
