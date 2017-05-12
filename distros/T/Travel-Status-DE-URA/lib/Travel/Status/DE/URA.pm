package Travel::Status::DE::URA;

use strict;
use warnings;
use 5.010;
use utf8;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

our $VERSION = '2.01';

# create CONSTANTS for different Return Types
use constant {
	TYPE_STOP       => 0,
	TYPE_PREDICTION => 1,
	TYPE_MESSAGE    => 2,
	TYPE_BASE       => 3,
	TYPE_URA        => 4,
};

use Carp qw(confess cluck);
use DateTime;
use Encode qw(encode decode);
use List::MoreUtils qw(firstval none uniq);
use LWP::UserAgent;
use Text::CSV;
use Travel::Status::DE::URA::Result;
use Travel::Status::DE::URA::Stop;

sub new {
	my ( $class, %opt ) = @_;

	my %lwp_options = %{ $opt{lwp_options} // { timeout => 10 } };

	my $ua = LWP::UserAgent->new(%lwp_options);
	my $response;

	if ( not( $opt{ura_base} and $opt{ura_version} ) ) {
		confess('ura_base and ura_version are mandatory');
	}

	my $self = {
		datetime => $opt{datetime}
		  // DateTime->now( time_zone => 'Europe/Berlin' ),
		developer_mode => $opt{developer_mode},
		ura_base       => $opt{ura_base},
		ura_version    => $opt{ura_version},
		full_routes    => $opt{calculate_routes} // 0,
		hide_past      => $opt{hide_past} // 1,
		stop           => $opt{stop},
		via            => $opt{via},
		via_id         => $opt{via_id},
		stop_id        => $opt{stop_id},
		line_id        => $opt{line_id},
		circle         => $opt{circle},
		post           => {
			StopAlso => 'False',

			# for easier debugging ordered in the returned order
			ReturnList => 'stoppointname,stopid,stoppointindicator,'
			  . 'latitude,longitude,lineid,linename,'
			  . 'directionid,destinationtext,vehicleid,tripid,estimatedtime'
		},
	};

	if ( $opt{with_messages} ) {
		$self->{post}{ReturnList} .= ',messagetext,messagetype';
	}
	if ( $opt{with_stops} ) {
		$self->{post}{StopAlso} = 'True';
	}

	$self->{ura_instant_url}
	  = $self->{ura_base} . '/instant_V' . $self->{ura_version};

	bless( $self, $class );

	$ua->env_proxy;

	if ( substr( $self->{ura_instant_url}, 0, 5 ) ne 'file:' ) {

		# filter by stop_id only if full_routes is not set
		if ( not $self->{full_routes} and $self->{stop_id} ) {
			$self->{post}{StopID} = $self->{stop_id};

			# filter for via as well to make via work
			if ( defined $self->{via_id} ) {
				$self->{post}{StopID} .= q{,} . $self->{via_id};
			}
		}

		# filter by line
		if ( $self->{line_id} ) {
			$self->{post}{LineID} = $self->{line_id};
		}

		# filter for Stops in circle (lon,lat,dist)
		if ( $self->{circle} ) {
			$self->{post}{Circle} = $self->{circle};
		}

		$response = $ua->post( $self->{ura_instant_url}, $self->{post} );
	}
	else {
		$response = $ua->get( $self->{ura_instant_url} );
	}

	if ( $response->is_error ) {
		$self->{errstr} = $response->status_line;
		return $self;
	}

	my $raw_str = $response->decoded_content;

	if ( $self->{developer_mode} ) {
		say decode( 'UTF-8', $raw_str );
	}

	# Fix encoding in case we're running through test files
	if ( substr( $self->{ura_instant_url}, 0, 5 ) eq 'file:' ) {
		$raw_str = encode( 'UTF-8', $raw_str );
	}
	$self->parse_raw_data($raw_str);

	return $self;
}

sub parse_raw_data {
	my ( $self, $raw_str ) = @_;
	my $csv = Text::CSV->new( { binary => 1 } );

	for my $dep ( split( /\r\n/, $raw_str ) ) {
		$dep =~ s{^\[}{};
		$dep =~ s{\]$}{};

		$csv->parse($dep);
		my @fields = $csv->fields;

		# encode all fields
		for my $i ( 1, 11 ) {
			$fields[$i] = encode( 'UTF-8', $fields[$i] );
		}

		push( @{ $self->{raw_list} }, \@fields );

		my $type = $fields[0];

		if ( $type == TYPE_STOP ) {
			my $stop_name = $fields[1];
			my $stop_id   = $fields[2];
			my $longitude = $fields[3];
			my $latitude  = $fields[4];

			# create Stop Dict
			if ( not exists $self->{stops}{$stop_id} ) {
				$self->{stops}{$stop_id} = Travel::Status::DE::URA::Stop->new(
					name      => decode( 'UTF-8', $stop_name ),
					id        => $stop_id,
					longitude => $longitude,
					latitude  => $latitude,
				);
			}
		}
		elsif ( $type == TYPE_MESSAGE ) {
			push(
				@{ $self->{messages} },
				{
					stop_name => $fields[1],
					stop_id   => $fields[2],

					# 0 = long text. 2 = short text for station displays?
					type => $fields[6],
					text => $fields[7],
				}
			);
		}
		elsif ( $type == TYPE_PREDICTION ) {
			push( @{ $self->{stop_names} }, $fields[1] );
		}
	}

	@{ $self->{stop_names} } = uniq @{ $self->{stop_names} };

	return $self;
}

sub get_stop_by_name {
	my ( $self, $name ) = @_;

	my $nname = lc($name);
	my $actual_match = firstval { $nname eq lc($_) } @{ $self->{stop_names} };

	if ($actual_match) {
		return $actual_match;
	}

	return ( grep { $_ =~ m{$name}i } @{ $self->{stop_names} } );
}

sub get_stops {
	my ($self) = @_;

	return $self->{stops};
}

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub messages_by_stop_id {
	my ( $self, $stop_id ) = @_;

	my @messages = grep { $_->{stop_id} == $stop_id } @{ $self->{messages} };
	@messages = map { $_->{text} } @messages;

	return @messages;
}

sub messages_by_stop_name {
	my ( $self, $stop_name ) = @_;

	my @messages
	  = grep { $_->{stop_name} eq $stop_name } @{ $self->{messages} };
	@messages = map { $_->{text} } @messages;

	return @messages;
}

sub results {
	my ( $self, %opt ) = @_;
	my @results;

	my $full_routes = $opt{calculate_routes} // $self->{full_routes} // 0;
	my $hide_past   = $opt{hide_past}        // $self->{hide_past}   // 1;
	my $line_id     = $opt{line_id}          // $self->{line_id};
	my $stop        = $opt{stop}             // $self->{stop};
	my $stop_id     = $opt{stop_id}          // $self->{stop_id};
	my $via         = $opt{via}              // $self->{via};
	my $via_id      = $opt{via_id}           // $self->{via_id};

	my $dt_now = $self->{datetime};
	my $ts_now = $dt_now->epoch;

	if ( $via or $via_id ) {
		$full_routes = 1;
	}

	for my $dep ( @{ $self->{raw_list} } ) {

		my (
			$type,        $stopname, $stopid,    $stopindicator,
			$longitude,   $latitude, $lineid,    $linename,
			$directionid, $dest,     $vehicleid, $tripid,
			$timestamp
		) = @{$dep};
		my ( @route_pre, @route_post );

		# only work on Prediction informations
		if ( $type != TYPE_PREDICTION ) {
			next;
		}

		if ( $line_id and not( $lineid eq $line_id ) ) {
			next;
		}

		if ( $stop and not( $stopname eq $stop ) ) {
			next;
		}

		if ( $stop_id and not( $stopid eq $stop_id ) ) {
			next;
		}

		if ( not $timestamp ) {
			cluck("departure element without timestamp: $dep");
			next;
		}

		$timestamp /= 1000;

		if ( $hide_past and $ts_now > $timestamp ) {
			next;
		}

		my $dt_dep = DateTime->from_epoch(
			epoch     => $timestamp,
			time_zone => 'Europe/Berlin'
		);
		my $ts_dep = $dt_dep->epoch;

		if ($full_routes) {
			my @route
			  = map { [ $_->[12] / 1000, $_->[1], $_->[2], $_->[4], $_->[5] ] }
			  grep { $_->[11] == $tripid }
			  grep { $_->[0] == 1 } @{ $self->{raw_list} };

			@route_pre  = grep { $_->[0] < $ts_dep } @route;
			@route_post = grep { $_->[0] > $ts_dep } @route;

			if ( $via
				and none { $_->[1] eq $via } @route_post )
			{
				next;
			}

			if ( $via_id
				and none { $_->[2] eq $via_id } @route_post )
			{
				next;
			}

			if ($hide_past) {
				@route_pre = grep { $_->[0] >= $ts_now } @route_pre;
			}

			@route_pre = map { $_->[0] }
			  sort { $a->[1] <=> $b->[1] }
			  map { [ $_, $_->[0] ] } @route_pre;
			@route_post = map { $_->[0] }
			  sort { $a->[1] <=> $b->[1] }
			  map { [ $_, $_->[0] ] } @route_post;

			@route_pre = map {
				Travel::Status::DE::URA::Stop->new(
					datetime => DateTime->from_epoch(
						epoch     => $_->[0],
						time_zone => 'Europe/Berlin'
					),
					name      => decode( 'UTF-8', $_->[1] ),
					id        => $_->[2],
					longitude => $_->[3],
					latitude  => $_->[4],
				  )
			} @route_pre;
			@route_post = map {
				Travel::Status::DE::URA::Stop->new(
					datetime => DateTime->from_epoch(
						epoch     => $_->[0],
						time_zone => 'Europe/Berlin'
					),
					name      => decode( 'UTF-8', $_->[1] ),
					id        => $_->[2],
					longitude => $_->[3],
					latitude  => $_->[4],
				  )
			} @route_post;
		}

		push(
			@results,
			Travel::Status::DE::URA::Result->new(
				datetime       => $dt_dep,
				dt_now         => $dt_now,
				line           => $linename,
				line_id        => $lineid,
				destination    => $dest,
				route_pre      => [@route_pre],
				route_post     => [@route_post],
				stop           => $stopname,
				stop_id        => $stopid,
				stop_indicator => $stopindicator,
			)
		);
	}

	@results = map { $_->[0] }
	  sort { $a->[1] <=> $b->[1] }
	  map { [ $_, $_->datetime->epoch ] } @results;

	return @results;
}

# static
sub get_services {
	return (
		{
			ura_base    => 'http://ivu.aseag.de/interfaces/ura',
			ura_version => 1,
			name        => 'Aachener Straßenbahn und Energieversorgungs AG',
			shortname   => 'ASEAG',
		},
		{
			ura_base    => 'http://ura.itcs.mvg-mainz.de/interfaces/ura',
			ura_version => 1,
			name        => 'MVG Mainz',
			shortname   => 'MvgMainz',
		},
		{
			ura_base    => 'http://countdown.api.tfl.gov.uk/interfaces/ura',
			ura_version => 1,
			name        => 'Transport for London',
			shortname   => 'TfL',
		}
	);
}

1;

__END__

=head1 NAME

Travel::Status::DE::URA - unofficial departure monitor for "Unified Realtime
API" data providers (e.g. ASEAG)

=head1 SYNOPSIS

    use Travel::Status::DE::URA;

    my $status = Travel::Status::DE::URA->new(
        ura_base => 'http://ivu.aseag.de/interfaces/ura',
        ura_version => '1',
        stop => 'Aachen Bushof'
    );

    for my $d ($status->results) {
        printf(
            "%s  %-5s %25s (in %d min)\n",
            $d->time, $d->line, $d->destination, $d->countdown
        );
    }

=head1 VERSION

version 2.01

=head1 DESCRIPTION

Travel::Status::DE::URA is an unofficial interface to URA-based realtime
departure monitors (as used e.g. by the ASEAG).  It reports all upcoming
departures at a given place in real-time.  Schedule information is not
included.

=head1 METHODS

=over

=item my $status = Travel::Status::DE::URA->new(I<%opt>)

Requests the departures as specified by I<opts> and returns a new
Travel::Status::DE::URA object.

The following two parameters are mandatory:

=over

=item B<ura_base> => I<ura_base>

The URA base url.

=item B<ura_version> => I<version>

The version, may be any string.

=back

The request URL is I<ura_base>/instant_VI<version>, so for
C<< http://ivu.aseag.de/interfaces/ura >>, C<< 1 >> this module will send
requests to C<< http://ivu.aseag.de/interfaces/ura/instant_V1 >>.

All remaining parameters are optional.

=over

=item B<lwp_options> => I<\%hashref>

Passed on to C<< LWP::UserAgent->new >>. Defaults to C<< { timeout => 10 } >>,
you can use an empty hashref to override it.

=item B<circle> => I<lon,lat,dist>

Only request departures for stops which are located up to I<dist> meters
away from the location specified by I<lon> and I<lat>. Example parameter:
"50.78496,6.10897,100".

=item B<with_messages> => B<0>|B<1>

When set to B<1> (or any other true value): Also requests stop messages from
the URA service. Thene can include texts such as "Expect delays due to snow and
ice" or "stop closed, use replacement stop X instead". Use
C<< $status->messages >> to access them.

=item B<with_stops> => B<0>|B<1>

When set to B<1> (or any other true value): Also request all stops satisfying
the specified parameters. They can be accessed with B<get_stops>. Defaults to
B<0>.

=back

Additionally, all options supported by C<< $status->results >> may be specified
here, causing them to be used as defaults. Note that while they can be
overridden later, they may limit the set of departures requested from the
server.

=item $status->errstr

In case of an HTTP request error, returns a string describing it. If none
occured, returns undef.

=item $status->get_stop_by_name(I<$stopname>)

Returns a list of stops matching I<$stopname>. For instance, if the stops
"Aachen Bushof", "Eupen Bushof", "Brand" and "Brandweiher" exist, the
parameter "bushof" will return "Aachen Bushof" and "Eupen Bushof", while
"brand" will only return "Brand".

=item $status->get_stops

Returns a hash reference describing all distinct stops returned by the request.
Each key is the unique ID of a stop and contains a
Travel::Status::DE::URA::Stop(3pm) object describing it.

Only works when $status was created with B<with_stops> set to a true value.
Otherwise, undef is returned.

=item $status->messages_by_stop_id($stop_id)

Returns a list of messages for the stop with the ID I<$stop_id>.
At the moment, each message is a simple string. This may change in the future.

=item $status->messages_by_stop_name($stop_id)

Returns a list of messages for the stop with the name I<$stop_name>.
At the moment, each message is a simple string. This may change in the future.

=item $status->results(I<%opt>)

Returns a list of Travel::Status::DE::URA::Result(3pm) objects, each describing
one departure.

Accepted parameters (all are optional):

=over

=item B<calculate_routes> => I<bool> (default 0)

When set to a true value: Compute routes for all results, enabling use of
their B<route_> accessors. Otherwise, those will just return nothing
(undef / empty list, depending on context).

=item B<hide_past> => I<bool> (default 1)

Do not include past departures in the result list and the computed timetables.

=item B<line_id> => I<ID>

Only return departures of line I<ID>.

=item B<stop> => I<name>

Only return departures at stop I<name>.

=item B<stop_id> => I<ID>

Only return departures at stop I<ID>.

=item B<via> => I<vianame>

Only return departures containing I<vianame> in their route after their
corresponding stop. Implies B<calculate_routes>=1.

=item B<via_id> => I<ID>

Only return departures containing I<ID> in their route after their
corresponding stop. Implies B<calculate_routes>=1.

=back

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * DateTime(3pm)

=item * List::MoreUtils(3pm)

=item * LWP::UserAgent(3pm)

=item * Text::CSV(3pm)

=back

=head1 BUGS AND LIMITATIONS

Many.

=head1 SEE ALSO

Travel::Status::DE::URA::Result(3pm).

=head1 AUTHOR

Copyright (C) 2013-2016 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
