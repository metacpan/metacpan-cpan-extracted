package Travel::Status::DE::DBRIS;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.020;
use utf8;

use Carp qw(confess);
use DateTime;
use DateTime::Format::Strptime;
use Encode qw(decode encode);
use JSON;
use LWP::UserAgent;

use Travel::Status::DE::DBRIS::Formation;
use Travel::Status::DE::DBRIS::JourneyAtStop;
use Travel::Status::DE::DBRIS::Journey;
use Travel::Status::DE::DBRIS::Location;

our $VERSION = '0.08';

# {{{ Constructors

sub new {
	my ( $obj, %conf ) = @_;

	my $ua = $conf{user_agent};

	if ( not $ua ) {
		my %lwp_options = %{ $conf{lwp_options} // { timeout => 10 } };
		$ua = LWP::UserAgent->new(%lwp_options);
		$ua->env_proxy;
	}

	my $self = {
		cache          => $conf{cache},
		developer_mode => $conf{developer_mode},
		messages       => [],
		results        => [],
		station        => $conf{station},
		ua             => $ua,
	};

	bless( $self, $obj );

	my $req;

	if ( my $station = $conf{station} ) {
		my $dt = $conf{datetime}
		  // DateTime->now( time_zone => 'Europe/Berlin' );
		my @mots
		  = (
			qw(ICE EC_IC IR REGIONAL SBAHN BUS SCHIFF UBAHN TRAM ANRUFPFLICHTIG)
		  );
		if ( $conf{modes_of_transit} ) {
			@mots = @{ $conf{modes_of_transit} // [] };
		}
		$req
		  = 'https://www.bahn.de/web/api/reiseloesung/abfahrten'
		  . '?datum='
		  . $dt->strftime('%Y-%m-%d')
		  . '&zeit='
		  . $dt->strftime('%H:%M:00')
		  . '&ortExtId='
		  . $station->{eva}
		  . '&ortId='
		  . $station->{id}
		  . '&mitVias=true&maxVias=8';
		for my $mot (@mots) {
			$req .= '&verkehrsmittel[]=' . $mot;
		}
	}
	elsif ( my $gs = $conf{geoSearch} ) {
		my $lat = $gs->{latitude};
		my $lon = $gs->{longitude};
		$req
		  = "https://www.bahn.de/web/api/reiseloesung/orte/nearby?lat=${lat}&long=${lon}&radius=9999&maxNo=100";
	}
	elsif ( my $query = $conf{locationSearch} ) {
		$req
		  = "https://www.bahn.de/web/api/reiseloesung/orte?suchbegriff=${query}&typ=ALL&limit=10";
	}
	elsif ( my $journey_id = $conf{journey} ) {
		my $poly = $conf{with_polyline} ? 'true' : 'false';
		$journey_id =~ s{[#]}{%23}g;
		$req
		  = "https://www.bahn.de/web/api/reiseloesung/fahrt?journeyId=${journey_id}&poly=${poly}";
	}
	elsif ( my $cf = $conf{formation} ) {
		my $datetime = $cf->{departure}->clone->set_time_zone('UTC');
		my $date     = $datetime->strftime('%Y-%m-%d');
		my $time     = $datetime->rfc3339 =~ s{(?=Z)}{.000}r;
		my %param    = (
			administrationId => 80,
			category         => $cf->{train_type},
			date             => $date,
			evaNumber        => $cf->{eva},
			number           => $cf->{train_number},
			time             => $time
		);
		$req
		  = 'https://www.bahn.de/web/api/reisebegleitung/wagenreihung/vehicle-sequence?'
		  . join( '&', map { $_ . '=' . $param{$_} } sort keys %param );
	}
	else {
		confess(
'station / formation / geoSearch  / locationSearch / journey must be specified'
		);
	}

	$self->{strptime_obj} //= DateTime::Format::Strptime->new(
		pattern   => '%Y-%m-%dT%H:%M:%S',
		time_zone => 'Europe/Berlin',
	);

	$self->{strpdate_obj} //= DateTime::Format::Strptime->new(
		pattern   => '%Y-%m-%d',
		time_zone => 'Europe/Berlin',
	);

	my $json = $self->{json} = JSON->new->utf8;

	if ( $conf{async} ) {
		$self->{req} = $req;
		return $self;
	}

	if ( $conf{json} ) {
		$self->{raw_json} = $conf{json};
	}
	else {
		if ( $self->{developer_mode} ) {
			say "requesting $req";
		}

		my ( $content, $error ) = $self->get_with_cache($req);

		if ($error) {
			$self->{errstr} = $error;
			return $self;
		}

		if ( $self->{developer_mode} ) {
			say decode( 'utf-8', $content );
		}

		$self->{raw_json} = $json->decode($content);
	}

	if ( $conf{station} ) {
		$self->parse_stationboard;
	}
	elsif ( $conf{journey} ) {
		$self->parse_journey( id => $conf{journey} );
	}
	elsif ( $conf{geoSearch} or $conf{locationSearch} ) {
		$self->parse_search;
	}
	elsif ( $conf{formation} ) {
		$self->parse_formation( $conf{formation} );
	}

	return $self;
}

sub new_p {
	my ( $obj, %conf ) = @_;
	my $promise = $conf{promise}->new;

	if (
		not(   $conf{station}
			or $conf{formation}
			or $conf{geoSearch}
			or $conf{locationSearch}
			or $conf{journey} )
	  )
	{
		return $promise->reject(
			'station / geoSearch / locationSearch / journey flag must be passed'
		);
	}

	my $self = $obj->new( %conf, async => 1 );
	$self->{promise} = $conf{promise};

	$self->get_with_cache_p( $self->{req} )->then(
		sub {
			my ($content) = @_;
			$self->{raw_json} = $self->{json}->decode($content);

			if ( $conf{station} ) {
				$self->parse_stationboard;
			}
			elsif ( $conf{journey} ) {
				$self->parse_journey( id => $conf{journey} );
			}
			elsif ( $conf{geoSearch} or $conf{locationSearch} ) {
				$self->parse_search;
			}
			elsif ( $conf{formation} ) {
				$self->parse_formation( $conf{formation} );
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

	my $reply = $self->{ua}->get($url);

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

	$self->{ua}->get_p($url)->then(
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

sub parse_journey {
	my ( $self, %opt ) = @_;

	$self->{result} = Travel::Status::DE::DBRIS::Journey->new(
		id           => $opt{id},
		json         => $self->{raw_json},
		strpdate_obj => $self->{strpdate_obj},
		strptime_obj => $self->{strptime_obj},
	);
}

sub parse_search {
	my ($self) = @_;

	@{ $self->{results} }
	  = map { Travel::Status::DE::DBRIS::Location->new( json => $_ ) }
	  @{ $self->{raw_json} // [] };

	return $self;
}

sub parse_stationboard {
	my ($self) = @_;

	# @{$self->{messages}} = map { Travel::Status::DE::DBRIS::Message->new(...) } @{$self->{raw_json}{globalMessages}/[]};

	@{ $self->{results} } = map {
		Travel::Status::DE::DBRIS::JourneyAtStop->new(
			json         => $_,
			strptime_obj => $self->{strptime_obj}
		)
	} @{ $self->{raw_json}{entries} // [] };

	return $self;
}

sub parse_formation {
	my ( $self, $conf ) = @_;

	$self->{result} = Travel::Status::DE::DBRIS::Formation->new(
		json       => $self->{raw_json},
		train_type => $conf->{train_type}
	);
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

# }}}

1;

__END__

=head1 NAME

Travel::Status::DE::DBRIS - Interface to bahn.de / bahnhof.de departure monitors

=head1 SYNOPSIS

Blocking variant:

    use Travel::Status::DE::DBRIS;
    
    my $status = Travel::Status::DE::DBRIS->new(station => 8000098);
    for my $r ($status->results) {
        printf(
            "%s +%-3d %10s -> %s\n",
            $r->dep->strftime('%H:%M'),
            $r->delay,
            $r->line,
            $r->dest_name
        );
    }

Non-blocking variant;

    use Mojo::Promise;
    use Mojo::UserAgent;
    use Travel::Status::DE::DBRIS;
    
    Travel::Status::DE::DBRIS->new_p(
        station => 8000098,
        promise => 'Mojo::Promise',
        user_agent => Mojo::UserAgent->new
    )->then(sub {
        my ($status) = @_;
        for my $r ($status->results) {
            printf(
                "%s +%-3d %10s -> %s\n",
                $r->dep->strftime('%H:%M'),
                $r->delay,
                $r->line,
                $r->dest_name
            );
        }
    })->wait;

=head1 VERSION

version 0.08

=head1 DESCRIPTION

Travel::Status::DE::DBRIS is an unofficial interface to bahn.de departure
monitor and train information APIs.

=head1 METHODS

=over

=item my $status = Travel::Status::DE::DBRIS->new(I<%opt>)

Requests item(s) as specified by I<opt> and returns a new
Travel::Status::DE::DBRIS element with the results.  Dies if the wrong
I<opt> were passed.

I<opt> must contain exactly one of the following keys:

=over

=item B<station> => I<$location>

Request station board (departures) for the station specified by I<$location>,
which must be either a Travel::Status::DE::DBRIS::Location(3pm) instance or a
hashref containing B<{> B<eva> => I<eva>, B<id> => I<id> B<}>.
Use B<geoSearch> or B<locatiorSearch> to obtain a location.
Results are available via C<< $status->results >>.

=item B<geoSearch> => B<{> B<latitude> => I<latitude>, B<longitude> => I<longitude> B<}>

Search for stations near I<latitude>, I<longitude>.
Results are available via C<< $status->results >>.

=item B<locationSearch> => I<query>

Search for stations whose name is equal or similar to I<query>. Results are
available via C<< $status->results >> and include the station ID needed for
station board requests.

=item B<journey> => I<journeyID>

Request trip details for I<journeyID>.
The result is available via C<< $status->result >>.

=item B<formation> => B<{> B<eva> => I<eva>, B<train_type> => I<type>, B<train_number> => I<number> B<}>

Request carriage formation of train I<type> I<number> at I<eva>.
The result is available via C<< $status->result >>.

=back

The following optional keys may be set.
Values in brackets indicate keys that are only relevant in certain request
modes, e.g. geoSearch or station.

=over

=item B<cache> => I<$obj>

A Cache::File(3pm) object used to cache realtime data requests. It should be
configured for an expiry of one to two minutes.

=item B<lwp_options> => I<\%hashref>

Passed on to C<< LWP::UserAgent->new >>. Defaults to C<< { timeout => 10 } >>,
you can use an empty hashref to unset the default.

=item B<modes_of_transit> => I<\@arrayref> (station)

Only consider the modes of transit given in I<arrayref> when listing
departures. Accepted modes of transit are:
ICE,
EC_IC,
IR,
REGIONAL,
SBAHN,
BUS,
SCHIFF,
UBAHN,
TRAM,
ANRUFPFLICHTIG.

By default, Travel::Status::DE::DBRIS considers all modes of transit.

=item B<json> => I<\%json>

Do not perform a request to bahn.de; load the prepared response provided in
I<json> instead. Note that you still need to specify B<station>, B<journey>,
etc. as appropriate.

=back

=item my $promise = Travel::Status::DE::DBRIS->new_p(I<%opt>)

Return a promise yielding a Travel::Status::DE::DBRIS instance (C<< $status >>)
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

=item $status->results (station, locationSearch, geoSearch)

Returns a list of Travel::Status::DE::DBRIS::Location(3pm) or Travel::Status::DE::DBRIS::JourneyAtStop(3pm) objects, depending on the arguments passed to B<new>.

=item $status->result (journey, formation)

Return a Travel::Status::DE::DBRIS::Journey(3pm) or Travel::Status::DE::DBRIS::Formation(3pm) object, depending on the arguments passed to B<new>.

=back

=head1 DIAGNOSTICS

Calling B<new> or B<new_p> with the B<developer_mode> key set to a true value
causes this module to print bahn.de requests and responses on the standard
output.

=head1 DEPENDENCIES

=over

=item * DateTime(3pm)

=item * DateTime::Format::Strptime(3pm)

=item * LWP::UserAgent(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is very much work-in-progress.

=head1 REPOSITORY

L<https://github.com/derf/Travel-Status-DE-DBRIS>

=head1 AUTHOR

Copyright (C) 2024-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
