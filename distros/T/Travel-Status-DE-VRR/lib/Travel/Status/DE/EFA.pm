package Travel::Status::DE::EFA;

use strict;
use warnings;
use 5.010;
use utf8;

our $VERSION = '3.15';

use Carp qw(confess cluck);
use DateTime;
use DateTime::Format::Strptime;
use Encode qw(encode);
use JSON;
use Travel::Status::DE::EFA::Departure;
use Travel::Status::DE::EFA::Info;
use Travel::Status::DE::EFA::Line;
use Travel::Status::DE::EFA::Services;
use Travel::Status::DE::EFA::Stop;
use Travel::Status::DE::EFA::Trip;
use LWP::UserAgent;

sub new_p {
	my ( $class, %opt ) = @_;
	my $promise = $opt{promise}->new;

	my $self;

	eval { $self = $class->new( %opt, async => 1 ); };
	if ($@) {
		return $promise->reject($@);
	}

	$self->{promise} = $opt{promise};

	$self->post_with_cache_p->then(
		sub {
			my ($content) = @_;
			$self->{response} = $self->{json}->decode($content);

			if ( $self->{developer_mode} ) {
				say $self->{json}->pretty->encode( $self->{response} );
			}

			$self->check_for_ambiguous();

			if ( $self->{errstr} ) {
				$promise->reject( $self->{errstr}, $self );
				return;
			}

			$promise->resolve($self);
			return;
		}
	)->catch(
		sub {
			my ( $err, $self ) = @_;
			$promise->reject($err);
			return;
		}
	)->wait;

	return $promise;
}

sub new {
	my ( $class, %opt ) = @_;

	$opt{timeout} //= 10;
	if ( $opt{timeout} <= 0 ) {
		delete $opt{timeout};
	}

	if (
		not(   $opt{coord}
			or $opt{name}
			or $opt{stopfinder}
			or $opt{stopseq}
			or $opt{from_json} )
	  )
	{
		confess('You must specify a name');
	}
	if ( $opt{type}
		and not( $opt{type} =~ m{ ^ (?: stop | stopID | address | poi ) $ }x ) )
	{
		confess('type must be stop, stopID, address, or poi');
	}

	if ( $opt{service} ) {
		if ( my $service
			= Travel::Status::DE::EFA::Services::get_service( $opt{service} ) )
		{
			$opt{efa_url} = $service->{url};
			if ( $opt{coord} ) {
				$opt{efa_url} .= '/XML_COORD_REQUEST';
			}
			elsif ( $opt{stopfinder} ) {
				$opt{efa_url} .= '/XML_STOPFINDER_REQUEST';
			}
			elsif ( $opt{stopseq} ) {
				$opt{efa_url} .= '/XML_STOPSEQCOORD_REQUEST';
			}
			else {
				$opt{efa_url} .= '/XML_DM_REQUEST';
			}
			$opt{time_zone} //= $service->{time_zone};
		}
	}

	$opt{time_zone} //= 'Europe/Berlin';

	if ( not $opt{efa_url} ) {
		confess('service or efa_url must be specified');
	}
	my $dt = $opt{datetime} // DateTime->now( time_zone => $opt{time_zone} );

	## no critic (RegularExpressions::ProhibitUnusedCapture)
	## no critic (Variables::ProhibitPunctuationVars)

	if (    $opt{time}
		and $opt{time} =~ m{ ^ (?<hour> \d\d? ) : (?<minute> \d\d ) $ }x )
	{
		$dt->set(
			hour   => $+{hour},
			minute => $+{minute}
		);
	}
	elsif ( $opt{time} ) {
		confess('Invalid time specified');
	}

	if (
		    $opt{date}
		and $opt{date} =~ m{ ^ (?<day> \d\d? ) [.] (?<month> \d\d? ) [.]
			(?<year> \d{4} )? $ }x
	  )
	{
		if ( $+{year} ) {
			$dt->set(
				day   => $+{day},
				month => $+{month},
				year  => $+{year}
			);
		}
		else {
			$dt->set(
				day   => $+{day},
				month => $+{month}
			);
		}
	}
	elsif ( $opt{date} ) {
		confess('Invalid date specified');
	}

	my $self = {
		cache          => $opt{cache},
		response       => $opt{from_json},
		developer_mode => $opt{developer_mode},
		efa_url        => $opt{efa_url},
		service        => $opt{service},
		strp_stopseq   => DateTime::Format::Strptime->new(
			pattern   => '%Y%m%d %H:%M',
			time_zone => $opt{time_zone},
		),
		strp_stopseq_s => DateTime::Format::Strptime->new(
			pattern   => '%Y%m%d %H:%M:%S',
			time_zone => $opt{time_zone},
		),

		json => JSON->new->utf8,
	};

	if ( $opt{coord} ) {

		# outputFormat => 'JSON' returns invalid JSON
		$self->{post} = {
			coord => sprintf( '%.7f:%.7f:%s',
				$opt{coord}{lon}, $opt{coord}{lat}, 'WGS84[DD.ddddd]' ),
			radius_1              => 1320,
			type_1                => 'STOP',
			coordListOutputFormat => 'list',
			max                   => 30,
			inclFilter            => 1,
			outputFormat          => 'rapidJson',
		};
	}
	elsif ( $opt{stopfinder} ) {

		# filter: 2 (stop) | 4 (street) | 8 (address) | 16 (crossing) | 32 (poi) | 64 (postcod)
		$self->{post} = {
			locationServerActive => 1,
			type_sf              => 'any',
			name_sf              => $opt{stopfinder}{name},
			anyObjFilter_sf      => 2,
			coordOutputFormat    => 'WGS84[DD.DDDDD]',
			outputFormat         => 'JSON',
		};
	}
	elsif ( $opt{stopseq} ) {

		# outputFormat => 'JSON' also works; leads to different output
		$self->{post} = {
			line              => $opt{stopseq}{stateless},
			stop              => $opt{stopseq}{stop_id},
			tripCode          => $opt{stopseq}{key},
			date              => $opt{stopseq}{date},
			time              => $opt{stopseq}{time},
			coordOutputFormat => 'WGS84[DD.DDDDD]',
			outputFormat      => 'rapidJson',
			useRealtime       => '1',
		};
	}
	else {
		$self->{post} = {
			language          => 'de',
			mode              => 'direct',
			outputFormat      => 'JSON',
			type_dm           => $opt{type} // 'stop',
			useProxFootSearch => $opt{proximity_search} ? '1' : '0',
			useRealtime       => '1',
			itdDateDay        => $dt->day,
			itdDateMonth      => $dt->month,
			itdDateYear       => $dt->year,
			itdTimeHour       => $dt->hour,
			itdTimeMinute     => $dt->minute,
			name_dm           => encode( 'UTF-8', $opt{name} ),
		};
	}

	if ( $opt{place} ) {
		$self->{post}{placeInfo_dm}  = 'invalid';
		$self->{post}{placeState_dm} = 'empty';
		$self->{post}{place_dm}      = encode( 'UTF-8', $opt{place} );
	}

	if ( $opt{full_routes} ) {
		$self->{post}->{depType}                = 'stopEvents';
		$self->{post}->{includeCompleteStopSeq} = 1;
		$self->{want_full_routes}               = 1;
	}

	bless( $self, $class );

	if ( $opt{user_agent} ) {
		$self->{ua} = $opt{user_agent};
	}
	else {
		my %lwp_options = %{ $opt{lwp_options} // { timeout => 10 } };
		$self->{ua} = LWP::UserAgent->new(%lwp_options);
		$self->{ua}->env_proxy;
	}

	if ( $self->{cache} ) {
		$self->{cache_key}
		  = $self->{efa_url} . '?'
		  . join( '&',
			map { $_ . '=' . $self->{post}{$_} } sort keys %{ $self->{post} } );
	}

	if ( $opt{async} ) {
		return $self;
	}

	if ( $self->{developer_mode} ) {
		say 'POST ' . $self->{efa_url};
		while ( my ( $key, $value ) = each %{ $self->{post} } ) {
			printf( "%30s = %s\n", $key, $value );
		}
	}

	if ( not $self->{response} ) {
		my ( $response, $error ) = $self->post_with_cache;

		if ($error) {
			$self->{errstr} = $error;
			return $self;
		}

		$self->{response} = $self->{json}->decode($response);
	}

	if ( $self->{developer_mode} ) {
		say $self->{json}->pretty->encode( $self->{response} );
	}

	$self->check_for_ambiguous();

	return $self;
}

sub post_with_cache {
	my ($self) = @_;
	my $cache  = $self->{cache};
	my $url    = $self->{efa_url};

	if ( $self->{developer_mode} ) {
		say 'POST ' . ( $self->{cache_key} // $url );
	}

	if ($cache) {
		my $content = $cache->thaw( $self->{cache_key} );
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

	my $reply = $self->{ua}->post( $url, $self->{post} );

	if ( $reply->is_error ) {
		return ( undef, $reply->status_line );
	}
	my $content = $reply->content;

	if ($cache) {
		$cache->freeze( $self->{cache_key}, \$content );
	}

	return ( $content, undef );
}

sub post_with_cache_p {
	my ($self) = @_;
	my $cache  = $self->{cache};
	my $url    = $self->{efa_url};

	if ( $self->{developer_mode} ) {
		say 'POST ' . ( $self->{cache_key} // $url );
	}

	my $promise = $self->{promise}->new;

	if ($cache) {
		my $content = $cache->thaw( $self->{cache_key} );
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

	$self->{ua}->post_p( $url, form => $self->{post} )->then(
		sub {
			my ($tx) = @_;
			if ( my $err = $tx->error ) {
				$promise->reject(
					"POST $url returned HTTP $err->{code} $err->{message}");
				return;
			}
			my $content = $tx->res->body;
			if ($cache) {
				$cache->freeze( $self->{cache_key}, \$content );
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

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub name_candidates {
	my ($self) = @_;

	if ( $self->{name_candidates} ) {
		return @{ $self->{name_candidates} };
	}
	return;
}

sub place_candidates {
	my ($self) = @_;

	if ( $self->{place_candidates} ) {
		return @{ $self->{place_candidates} };
	}
	return;
}

sub check_for_ambiguous {
	my ($self) = @_;

	my $json = $self->{response};

	if ( $json->{departureList} ) {
		return;
	}

	for my $m ( @{ $json->{dm}{message} // [] } ) {
		if ( $m->{name} eq 'error' and $m->{value} eq 'name list' ) {
			$self->{errstr}          = "ambiguous name parameter";
			$self->{name_candidates} = [];
			for my $point ( @{ $json->{dm}{points} // [] } ) {
				my $place = $point->{ref}{place};
				push(
					@{ $self->{name_candidates} },
					Travel::Status::DE::EFA::Stop->new(
						place     => $place,
						full_name => $point->{name},
						name      => $point->{name} =~ s{\Q$place\E,? ?}{}r,
						id_num    => $point->{ref}{id},
					)
				);
			}
			return;
		}
		if ( $m->{name} eq 'error' and $m->{value} eq 'place list' ) {
			$self->{errstr}           = "ambiguous name parameter";
			$self->{place_candidates} = [];
			for my $point ( @{ $json->{dm}{points} // [] } ) {
				my $place = $point->{ref}{place};
				push(
					@{ $self->{place_candidates} },
					Travel::Status::DE::EFA::Stop->new(
						place     => $place,
						full_name => $point->{name},
						name      => $point->{name} =~ s{\Q$place\E,? ?}{}r,
						id_num    => $point->{ref}{id},
					)
				);
			}
			return;
		}
	}

	return;
}

sub stop {
	my ($self) = @_;
	if ( $self->{stop} ) {
		return $self->{stop};
	}

	my $point = $self->{response}{dm}{points}{point};
	my $place = $point->{ref}{place};

	$self->{stop} = Travel::Status::DE::EFA::Stop->new(
		place     => $place,
		full_name => $point->{name},
		name      => $point->{name} =~ s{\Q$place\E,? ?}{}r,
		id_num    => $point->{ref}{id},
		id_code   => $point->{ref}{gid},
	);

	return $self->{stop};
}

sub stops {
	my ($self) = @_;

	if ( $self->{stops} ) {
		return @{ $self->{stops} };
	}

	my $stops = $self->{response}{dm}{itdOdvAssignedStops} // [];

	if ( ref($stops) eq 'HASH' ) {
		$stops = [$stops];
	}

	my @stops;
	for my $stop ( @{$stops} ) {
		push(
			@stops,
			Travel::Status::DE::EFA::Stop->new(
				place     => $stop->{place},
				name      => $stop->{name},
				full_name => $stop->{nameWithPlace},
				id_num    => $stop->{stopID},
				id_code   => $stop->{gid},
			)
		);
	}

	$self->{stops} = \@stops;
	return @stops;
}

sub infos {
	my ($self) = @_;

	if ( $self->{infos} ) {
		return @{ $self->{infos} };
	}

	for my $info ( @{ $self->{response}{dm}{points}{point}{infos} // [] } ) {
		push(
			@{ $self->{infos} },
			Travel::Status::DE::EFA::Info->new( json => $info )
		);
	}

	return @{ $self->{infos} // [] };
}

sub lines {
	my ($self) = @_;

	if ( $self->{lines} ) {
		return @{ $self->{lines} };
	}

	for my $line ( @{ $self->{response}{servingLines}{lines} // [] } ) {
		push( @{ $self->{lines} }, $self->parse_line($line) );
	}

	return @{ $self->{lines} // [] };
}

sub parse_line {
	my ( $self, $line ) = @_;

	my $mode = $line->{mode} // {};

	return Travel::Status::DE::EFA::Line->new(
		type       => $mode->{product},
		name       => $mode->{name},
		number     => $mode->{number},
		direction  => $mode->{destination},
		valid      => $mode->{timetablePeriod},
		mot        => $mode->{product},
		operator   => $mode->{diva}{operator},
		identifier => $mode->{diva}{globalId},

	);
}

sub results {
	my ($self) = @_;

	if ( $self->{results} ) {
		return @{ $self->{results} };
	}

	if ( $self->{post}{coord} ) {
		return $self->results_coord;
	}
	elsif ( $self->{post}{name_sf} ) {
		return $self->results_stopfinder;
	}
	else {
		return $self->results_dm;
	}
}

sub results_coord {
	my ($self) = @_;
	my $json = $self->{response};

	my @results;
	for my $stop ( @{ $json->{locations} // [] } ) {
		push(
			@results,
			Travel::Status::DE::EFA::Stop->new(
				place      => $stop->{parent}{name},
				full_name  => $stop->{properties}{STOP_NAME_WITH_PLACE},
				distance_m => $stop->{properties}{distance},
				name       => $stop->{name},
				id_code    => $stop->{id},
			)
		);
	}

	$self->{results} = \@results;

	return @results;
}

sub results_stopfinder {
	my ($self) = @_;
	my $json = $self->{response};

	my @results;

	# Edge case: there is just a single result.
	# Oh EFA, you so silly.
	if ( ref( $json->{stopFinder}{points} ) eq 'HASH'
		and exists $json->{stopFinder}{points}{point} )
	{
		$json->{stopFinder}{points} = [ $json->{stopFinder}{points}{point} ];
	}

	for my $stop ( @{ $json->{stopFinder}{points} // [] } ) {
		push(
			@results,
			Travel::Status::DE::EFA::Stop->new(
				place     => $stop->{ref}{place},
				full_name => $stop->{name},
				name      => $stop->{object},
				id_num    => $stop->{ref}{id},
				id_code   => $stop->{ref}{gid},
			)
		);
	}

	$self->{results} = \@results;

	return @results;
}

sub results_dm {
	my ($self) = @_;
	my $json = $self->{response};

	# Oh EFA, you so silly
	if ( $json->{departureList} and ref( $json->{departureList} ) eq 'HASH' ) {
		$json->{departureList} = [ $json->{departureList}{departure} ];
	}

	my @results;
	for my $departure ( @{ $json->{departureList} // [] } ) {
		push(
			@results,
			Travel::Status::DE::EFA::Departure->new(
				json           => $departure,
				strp_stopseq   => $self->{strp_stopseq},
				strp_stopseq_s => $self->{strp_stopseq_s}
			)
		);
	}

	@results = map { $_->[0] }
	  sort { $a->[1] <=> $b->[1] }
	  map { [ $_, $_->countdown ] } @results;

	$self->{results} = \@results;

	return @results;
}

sub result {
	my ($self) = @_;

	return Travel::Status::DE::EFA::Trip->new( json => $self->{response} );
}

# static
sub get_service_ids {
	return Travel::Status::DE::EFA::Services::get_service_ids(@_);
}

sub get_services {
	my @services;
	for my $service ( Travel::Status::DE::EFA::Services::get_service_ids() ) {
		my %desc
		  = %{ Travel::Status::DE::EFA::Services::get_service($service) };
		$desc{shortname} = $service;
		push( @services, \%desc );
	}
	return @services;
}

# static
sub get_service {
	return Travel::Status::DE::EFA::Services::get_service(@_);
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA - unofficial EFA departure monitor

=head1 SYNOPSIS

    use Travel::Status::DE::EFA;

    my $status = Travel::Status::DE::EFA->new(
        service => 'VRR',
        name => 'Essen Helenenstr'
    );

    for my $d ($status->results) {
        printf(
            "%s %-8s %-5s %s\n",
            $d->datetime->strftime('%H:%M'),
            $d->platform_name, $d->line, $d->destination
        );
    }

=head1 VERSION

version 3.15

=head1 DESCRIPTION

Travel::Status::DE::EFA is an unofficial interface to EFA-based departure
monitors.

It can serve as a departure monitor, request details about a specific
trip/journey, and look up public transport stops by name or geolocation.
The operating mode depends on its constructor arguments.

=head1 METHODS

=over

=item my $status = Travel::Status::DE::EFA->new(I<%opt>)

Requests data as specified by I<opts> and returns a new Travel::Status::DE::EFA
object. B<service> and exactly one of B<coord>, B<stopfinder>, B<stopseq> or
B<name> are mandatory.  Dies if the wrong I<opts> were passed.

Arguments:

=over

=item B<service> => I<name>

EFA service. See C<< efa-m --list >> for known services.
If you found a service not listed there, please notify
E<lt>derf+efa@finalrewind.orgE<gt>.

=item B<coord> => I<hashref>

Look up stops in the vicinity of the given coordinates.  I<hashref> must
contain a B<lon> and a B<lat> element providing WGS84 longitude/latitude.

=item B<stopfinder> => { B<name> => I<name> }

Look up stops matching I<name>.

=item B<stopseq> => I<hashref>

Look up trip details. I<hashref> must provide B<stateless> (line ID),
B<stop_id> (stop ID used as start for the reported route), B<key> (line trip
number), and B<date> (departure date as YYYYMMDD string).

=item B<name> => I<name>

List departure for address / point of interest / stop I<name>.

=item B<place> => I<place>

Name of the place/city

=item B<type> => B<address>|B<poi>|B<stop>|B<stopID>

Type of the following I<name>.  B<poi> means "point of interest".  Defaults to
B<stop> (stop/station name).

=item B<datetime> => I<DateTime object>

Request departures for the date/time specified by I<DateTime object>.
Default: now.

=item B<efa_encoding> => I<encoding>

Some EFA servers do not correctly specify their response encoding. If you
observe encoding issues, you can manually specify it here. Example:
iso-8859-15.

=item B<full_routes> => B<0>|B<1>

If true: Request full routes for all departures from the backend. This
enables the B<route_pre>, B<route_post> and B<route_interesting> accessors in
Travel::Status::DE::EFA::Departure(3pm).

=item B<proximity_search> => B<0>|B<1>

If true: Show departures for stops in the proximity of the requested place
as well.

=item B<timeout> => I<seconds>

Request timeout, the argument is passed on to LWP::UserAgent(3pm).
Default: 10 seconds. Set to 0 or a negative value to disable it.

=back

=item my $status_p = Travel::Status::DE::EFA->new_p(I<%opt>)

Returns a promise that resolves into a Travel::Status::DE::EFA instance
($status) on success and rejects with an error message on failure. In case
the error occured after construction of the Travel::Status::DE::EFA object
(e.g. due to an ambiguous name/place parameter), the second argument of the
rejected promise holds a Travel::Status::DE::EFA instance that can be used
to query place/name candidates (see name_candidates and place_candidates).

In addition to the arguments of B<new>, the following mandatory arguments must
be set.

=over

=item B<promise> => I<promises module>

Promises implementation to use for internal promises as well as B<new_p> return
value. Recommended: Mojo::Promise(3pm).

=item B<user_agent> => I<user agent>

User agent instance to use for asynchronous requests. The object must implement
a B<post_p> function. Recommended: Mojo::UserAgent(3pm).

=back

=item $status->errstr

In case of an HTTP request or EFA error, returns a string describing it. If
none occured, returns undef.

=item $status->lines

Returns a list of Travel::Status::DE::EFA::Line(3pm) objects, each one
describing one line servicing the selected station.

=item $status->name_candidates

Returns a list of B<name> candidates if I<name> is ambiguous. Returns
nothing (undef / empty list) otherwise.

=item $status->place_candidates

Returns a list of B<place> candidates if I<place> is ambiguous. Returns
nothing (undef / empty list) otherwise.

=item $status->stop

Returns a Travel::Status::DE::EFA::Stop(3pm) instance describing the requested
stop.

=item $status->stops

In case the requested place/name is served by multiple stops and the backend
provides a list of those: returns a list of Travel::Status::DE::EFA::Stop(3pm)
instances describing each of them. Returns an empty list otherwise.

=item $status->results

In departure monitor mode: returns a list of
Travel::Status::DE::EFA::Departure(3pm) objects, each one describing one
departure.

In coord or stopfinder mode: returns a list of
Travel::Status::DE::EFA::Stop(3pm) objects.

=item $status->result

In stopseq mode: Returns a Travel::Status::DE::EFA::Trip(3pm) object.

=item Travel::Status::DE::EFA::get_service_ids()

Returns the list of supported services (backends).

=item Travel::Status::DE::EFA::get_service(I<service>)

Returns a hashref describing the requested I<service> ID with the following keys.

=over

=item B<name> => I<string>

Provider name, e.g. Verkehrsverbund Oberelbe.

=item B<url> => I<string>

Backend base URL.

=item B<homepage> => I<string> (optional)

Provider homepage.

=item B<languages> => I<arrayref> (optional)

Supportde languages, e.g. de, en.

=item B<coverage> => I<hashref>

Area in which the  service  provides  near-optimal  coverage.  Typically,  this
means  a (nearly)  complete  list  of  departures  and  real-time  data.  The
hashref contains two optional keys: B<area> (GeoJSON) and B<regions> (list of
strings, e.g. "DE" or "CH-BE").

=back

=item Travel::Status::DE::EFA::get_services()

Returns a list of hashrefs describing all supported services. In addition
to the keys listed above, each service contains a B<shortname> (service ID).

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * DateTime(3pm)

=item * DateTime::Format::Strptime(3pm)

=item * JSON(3pm)

=item * LWP::UserAgent(3pm)

=back

=head1 BUGS AND LIMITATIONS

The API is not exposed completely.

=head1 SEE ALSO

efa-m(1), Travel::Status::DE::EFA::Departure(3pm).

=head1 AUTHOR

Copyright (C) 2011-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
