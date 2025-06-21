package Travel::Status::MOTIS;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.020;
use utf8;

use Carp qw(confess);
use DateTime;
use DateTime::Format::ISO8601;
use Encode qw(decode encode);
use JSON;

use LWP::UserAgent;

use URI;

use Travel::Status::MOTIS::Services;
use Travel::Status::MOTIS::TripAtStopover;
use Travel::Status::MOTIS::Trip;
use Travel::Status::MOTIS::Stopover;
use Travel::Status::MOTIS::Stop;

our $VERSION = '0.03';

# {{{ Endpoint Definition

# Data sources: <https://github.com/public-transport/transport-apis>.
# Thanks to Jannis R / @derhuerst and all contributors for maintaining these.
my $motis_instance = Travel::Status::MOTIS::Services::get_service_ref();

# }}}
# {{{ Constructors

sub new {
	my ( $obj, %conf ) = @_;
	my $service = $conf{service};

	if ( not defined $service ) {
		confess("You must specify a service");
	}

	if ( defined $service and not exists $motis_instance->{$service} ) {
		confess("The service '$service' is not supported");
	}

	my $user_agent = $conf{user_agent};

	if ( not $user_agent ) {
		$user_agent
		  = LWP::UserAgent->new( %{ $conf{lwp_options} // { timeout => 10 } } );
	}

	my $self = {
		cache          => $conf{cache},
		developer_mode => $conf{developer_mode},
		results        => [],
		station        => $conf{station},
		user_agent     => $user_agent,
		time_zone      => $conf{time_zone} // 'local',
	};

	bless( $self, $obj );

	my $request_url = URI->new;

	if ( my $stop_id = $conf{stop_id} ) {
		my $timestamp = $conf{timestamp} // DateTime->now;

		my @modes_of_transit = (qw(TRANSIT));

		if ( $conf{modes_of_transit} ) {
			@modes_of_transit = @{ $conf{modes_of_transit} // [] };
		}

		$request_url->path('api/v1/stoptimes');
		$request_url->query_form(
			time   => DateTime::Format::ISO8601->format_datetime($timestamp),
			stopId => $stop_id,
			n      => $conf{results} // 10,
			mode   => join( ',', @modes_of_transit ),
		);
	}
	elsif ( my $trip_id = $conf{trip_id} ) {
		$request_url->path('api/v2/trip');
		$request_url->query_form(
			tripId => $trip_id,
		);
	}
	elsif ( my $coordinates = $conf{stops_by_coordinate} ) {
		my $lat = $coordinates->{lat};
		my $lon = $coordinates->{lon};

		$request_url->path('api/v1/reverse-geocode');
		$request_url->query_form(
			type  => 'STOP',
			place => "$lat,$lon,0",
		);
	}
	elsif ( my $query = $conf{stops_by_query} ) {
		$request_url->path('api/v1/geocode');
		$request_url->query_form(
			text => $query,
		);
	}
	else {
		confess(
'stop_id / trip_id / stops_by_coordinate / stops_by_query must be specified'
		);
	}

	my $json = $self->{json} = JSON->new->utf8;

	$request_url
	  = $request_url->abs( $motis_instance->{$service}{endpoint} )->as_string;

	if ( $conf{async} ) {
		$self->{request_url} = $request_url;
		return $self;
	}

	if ( $conf{json} ) {
		$self->{raw_json} = $conf{json};
	}
	else {
		if ( $self->{developer_mode} ) {
			say "requesting $request_url";
		}

		my ( $content, $error ) = $self->get_with_cache($request_url);

		if ($error) {
			$self->{errstr} = $error;
			return $self;
		}

		if ( $self->{developer_mode} ) {
			say decode( 'utf-8', $content );
		}

		$self->{raw_json} = $json->decode($content);
	}

	if ( $conf{stop_id} ) {
		$self->parse_trips_at_stopover;
	}
	elsif ( $conf{trip_id} ) {
		$self->parse_trip;
	}
	elsif ( $conf{stops_by_query} or $conf{stops_by_coordinate} ) {
		$self->parse_stops_by;
	}

	return $self;
}

sub new_p {
	my ( $obj, %conf ) = @_;

	my $promise = $conf{promise}->new;

	if (
		not(   $conf{stop_id}
			or $conf{trip_id}
			or $conf{stops_by_coordinate}
			or $conf{stops_by_query} )
	  )
	{
		return $promise->reject(
'stop_id / trip_id / stops_by_coordinate / stops_by_query flag must be passed'
		);
	}

	my $self = $obj->new( %conf, async => 1 );

	$self->{promise} = $conf{promise};

	$self->get_with_cache_p( $self->{request_url} )->then(
		sub {
			my ($content) = @_;
			$self->{raw_json} = $self->{json}->decode($content);

			if ( $conf{stop_id} ) {
				$self->parse_trips_at_stopover;
			}
			elsif ( $conf{trip_id} ) {
				$self->parse_trip;
			}
			elsif ( $conf{stops_by_query} or $conf{stops_by_coordinate} ) {
				$self->parse_stops_by;
			}

			if ( $self->errstr ) {
				$promise->reject( $self->errstr, $self );
			}
			else {
				$promise->resolve($self);
			}

			return;
		}
	)->catch(
		sub {
			my ($err) = @_;
			$promise->reject($err);
			return;
		}
	)->wait;

	return $promise;
}

# }}}
# {{{ Internal Helpers

sub get_with_cache {
	my ( $self, $url ) = @_;
	my $cache = $self->{cache};

	if ( $self->{developer_mode} ) {
		say "GET $url";
	}

	if ($cache) {
		my $content = $cache->thaw($url);
		if ($content) {
			if ( $self->{developer_mode} ) {
				say '  cache hit';
			}

			return ( ${$content}, undef );
		}
	}

	if ( $self->{developer_mode} ) {
		say '  cache miss';
	}

	my $reply = $self->{user_agent}->get($url);

	if ( $reply->is_error ) {
		return ( undef, $reply->status_line );
	}

	my $content = $reply->content;

	if ($cache) {
		$cache->freeze( $url, \$content );
	}

	return ( $content, undef );
}

sub get_with_cache_p {
	my ( $self, $url ) = @_;

	my $cache = $self->{cache};

	if ( $self->{developer_mode} ) {
		say "GET $url";
	}

	my $promise = $self->{promise}->new;

	if ($cache) {
		my $content = $cache->thaw($url);
		if ($content) {
			if ( $self->{developer_mode} ) {
				say '  cache hit';
			}

			return $promise->resolve( ${$content} );
		}
	}

	if ( $self->{developer_mode} ) {
		say '  cache miss';
	}

	$self->{user_agent}->get_p($url)->then(
		sub {
			my ($tx) = @_;
			if ( my $err = $tx->error ) {
				$promise->reject(
					"GET $url returned HTTP $err->{code} $err->{message}");

				return;
			}

			my $content = $tx->res->body;

			if ($cache) {
				$cache->freeze( $url, \$content );
			}

			$promise->resolve($content);
			return;
		}
	)->catch(
		sub {
			my ($err) = @_;
			$promise->reject($err);
			return;
		}
	)->wait;

	return $promise;
}

sub parse_trip {
	my ( $self, %opt ) = @_;

	$self->{result} = Travel::Status::MOTIS::Trip->new(
		json      => $self->{raw_json},
		time_zone => $self->{time_zone},
	);
}

sub parse_stops_by {
	my ($self) = @_;

	@{ $self->{results} } = map {
		$_->{type} eq 'STOP'
		  ? Travel::Status::MOTIS::Stop->from_match( json => $_ )
		  : ()
	} @{ $self->{raw_json} // [] };

	return $self;
}

sub parse_trips_at_stopover {
	my ($self) = @_;

	@{ $self->{results} } = map {
		Travel::Status::MOTIS::TripAtStopover->new(
			json      => $_,
			time_zone => $self->{time_zone},
		)
	} @{ $self->{raw_json}{stopTimes} // [] };

	return $self;
}

# }}}
# {{{ Public Functions

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub results {
	my ($self) = @_;
	return @{ $self->{results} };
}

sub result {
	my ($self) = @_;
	return $self->{result};
}

# static
sub get_services {
	my @services;
	for my $service ( sort keys %{$motis_instance} ) {
		my %desc = %{ $motis_instance->{$service} };
		$desc{shortname} = $service;
		push( @services, \%desc );
	}
	return @services;
}

# static
sub get_service {
	my ($service) = @_;

	if ( defined $service and exists $motis_instance->{$service} ) {
		return $motis_instance->{$service};
	}
	return;
}

# }}}

1;

__END__

=head1 NAME

Travel::Status::MOTIS - An interface to the MOTIS routing service

=head1 SYNOPSIS

Blocking variant:

	use Travel::Status::MOTIS;
	
	my $status = Travel::Status::MOTIS->new(
		service => 'RNV',
		stop_id => 'rnv_241721',
	);

	for my $result ($status->results) {
		printf(
			"%s +%-3d %10s -> %s\n",
			$result->stopover->departure->strftime('%H:%M'),
			$result->stopover->delay,
			$result->route_name,
			$result->headsign,
		);
	}

Non-blocking variant;

	use Mojo::Promise;
	use Mojo::UserAgent;
	use Travel::Status::MOTIS;
	
	Travel::Status::MOTIS->new_p(
		service => 'RNV',
		stop_id => 'rnv_241721',
		promise => 'Mojo::Promise',
		user_agent => Mojo::UserAgent->new
	)->then(sub {
		my ($status) = @_;
		for my $result ($status->results) {
			printf(
				"%s +%-3d %10s -> %s\n",
				$result->stopover->departure->strftime('%H:%M'),
				$result->stopover->delay,
				$result->route_name,
				$result->headsign,
			);
		}
	})->wait;

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Travel::Status::MOTIS is an interface to the departures and trips
provided by MOTIS routing services

=head1 METHODS

=over

=item my $status = Travel::Status::MOTIS->new(I<%opt>)

Requests item(s) as specified by I<opt> and returns a new
Travel::Status::MOTIS element with the results. Dies if the wrong
I<opt> were passed.

I<opt> must contain exactly one of the following keys:

=over

=item B<stop_id> => I<$stop_id>

Request stop board (departures) for the stop specified by I<$stop_id>.
Use B<stops_by_coordinate> or B<stops_by_query> to obtain a stop id.
Results are available via C<< $status->results >>.

=item B<stops_by_coordinate> => B<{> B<lat> => I<latitude>, B<lon> => I<longitude> B<}>

Search for stops near I<latitude>, I<longitude>.
Results are available via C<< $status->results >>.

=item B<stops_by_query> => I<$query>

Search for stops whose name is equal or similar to I<query>. Results are
available via C<< $status->results >> and include the stop id needed for
stop board requests.

=item B<trip_id> => I<$trip_id>

Request trip details for I<$trip_id>.
The result is available via C<< $status->result >>.

=back

The following optional keys may be set.
Values in brackets indicate keys that are only relevant in certain request
modes, e.g. stops_by_coordinate or stop_id.

=over

=item B<cache> => I<$obj>

A Cache::File(3pm) object used to cache realtime data requests. It should be
configured for an expiry of one to two minutes.

=item B<lwp_options> => I<\%hashref>

Passed on to C<< LWP::UserAgent->new >>. Defaults to C<< { timeout => 10 } >>,
you can use an empty hashref to unset the default.

=item B<modes_of_transit> => I<\@arrayref> (stop_id)

Only consider the modes of transit given in I<arrayref> when listing
departures. Accepted modes of transit are:
TRANSIT (same as RAIL, SUBWAY, TRAM, BUS, FERRY, AIRPLANE, COACH),
TRAM,
SUBWAY,
FERRY,
AIRPLANE,
BUS,
COACH,
RAIL (same as HIGHSPEED_RAIL, LONG_DISTANCE_RAIL, NIGHT_RAIL, REGIONAL_RAIL, REGIONAL_FAST_RAIL),
METRO,
HIGHSPEED_RAIL,
LONG_DISTANCE,
NIGHT_RAIL,
REGIONAL_FAST_RAIL,
REGIONAL_RAIL.

By default, Travel::Status::MOTIS uses TRANSIT.

=item B<json> => I<\%json>

Do not perform a request to MOTIS; load the prepared response provided in
I<json> instead. Note that you still need to specify B<stop_id>, B<trip_id>,
etc. as appropriate.

=item B<time_zone> => I<$time_zone>

A timezone to normalize timestamps to, defaults to 'local'.

=back

=item my $promise = Travel::Status::MOTIS->new_p(I<%opt>)

Return a promise yielding a Travel::Status::MOTIS instance (C<< $status >>)
on success, or an error message (same as C<< $status->errstr >>) on failure.

In addition to the arguments of B<new>, the following mandatory arguments must
be set:

=over

=item B<promise> => I<promises module>

Promises implementation to use for internal promises as well as B<new_p> return
value. Recommended: Mojo::Promise(3pm).

=item B<user_agent> => I<user agent>

User agent instance to use for asynchronous requests. The object must support
promises (i.e., it must implement a C<< get_p >> function). Recommended:
Mojo::UserAgent(3pm).

=back

=item $status->errstr

In case of a fatal HTTP request or backend error, returns a string describing
it. Returns undef otherwise.

=item $status->results (stop_id, stops_by_query, stops_by_coordinate)

Returns a list of Travel::Status::MOTIS::Stop(3pm) or Travel::Status::MOTIS::TripAtStopover(3pm) objects, depending on the arguments passed to B<new>.

=item $status->result (trip_id)

Returns a Travel::Status::MOTIS::Trip(3pm) object, depending on the arguments passed to B<new>.

=back

=head1 DIAGNOSTICS

Calling B<new> or B<new_p> with the B<developer_mode> key set to a true value
causes this module to print MOTIS requests and responses on the standard
output.

=head1 DEPENDENCIES

=over

=item * DateTime(3pm)

=item * DateTime::Format::ISO8601(3pm)

=item * LWP::UserAgent(3pm)

=item * URI(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is designed for use in travelynx (L<https://finalrewind.org/projects/travelynx/>) and
might not contain functionality needed otherwise.

=head1 REPOSITORY

L<TBD>

=head1 AUTHOR

Copyright (C) 2025 networkException E<lt>git@nwex.deE<gt>

Based on Travel::Status::DE::DBRIS

Copyright (C) 2024-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
