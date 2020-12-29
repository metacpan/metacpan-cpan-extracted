package Travel::Status::DE::DBWagenreihung;

use strict;
use warnings;
use 5.020;

our $VERSION = '0.05';

use Carp qw(cluck confess);
use JSON;
use List::Util qw(uniq);
use LWP::UserAgent;
use Travel::Status::DE::DBWagenreihung::Section;
use Travel::Status::DE::DBWagenreihung::Wagon;

sub new {
	my ( $class, %opt ) = @_;

	if ( not $opt{train_number} and not $opt{from_json} ) {
		confess('train_number option must be set');
	}

	if ( not $opt{departure} and not $opt{from_json} ) {
		confess('departure option must be set');
	}

	my $self = {
		api_base => $opt{api_base}
		  // 'https://www.apps-bahn.de/wr/wagenreihung/1.0',
		developer_mode => $opt{developer_mode},
		cache          => $opt{cache},
		departure      => $opt{departure},
		from_json      => $opt{from_json},
		json           => JSON->new,
		serializable   => $opt{serializable},
		train_number   => $opt{train_number},
		user_agent     => $opt{user_agent},
	};

	bless( $self, $class );

	if ( not $self->{user_agent} ) {
		my %lwp_options = %{ $opt{lwp_options} // { timeout => 10 } };
		$self->{user_agent} = LWP::UserAgent->new(%lwp_options);
		$self->{user_agent}->env_proxy;
	}

	$self->get_wagonorder;

	return $self;
}

sub get_wagonorder {
	my ($self) = @_;

	my $api_base     = $self->{api_base};
	my $cache        = $self->{cache};
	my $train_number = $self->{train_number};

	my $datetime = $self->{departure};

	if ( ref($datetime) eq 'DateTime' ) {
		$datetime = $datetime->strftime('%Y%m%d%H%M');
	}

	my $json = $self->{from_json};

	if ( not $json ) {
		my ( $content, $err )
		  = $self->get_with_cache( $cache,
			"${api_base}/${train_number}/${datetime}" );

		if ($err) {
			$self->{errstr} = "Failed to fetch station data: $err";
			return;
		}
		$json = $self->{json}->utf8->decode($content);
	}

	if ( exists $json->{error} ) {
		$self->{errstr} = 'Backend error: ' . $json->{error}{msg};
		return;
	}

	if (    @{ $json->{data}{istformation}{allFahrzeuggruppe} // [] } == 0
		and @{ $json->{data}{istformation}{halt} // [] } == 0 )
	{
		$self->{errstr} = 'No wagon order available';
		return;
	}

	$self->{data} = $json->{data};
	$self->{meta} = $json->{meta};
}

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub direction {
	my ($self) = @_;

	if ( not exists $self->{direction} ) {

		# direction is set while parsing wagons
		$self->wagons;
	}

	return $self->{direction};
}

sub has_bad_wagons {
	my ($self) = @_;

	if ( defined $self->{has_bad_wagons} ) {
		return $self->{has_bad_wagons};
	}

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		for my $wagon ( @{ $group->{allFahrzeug} } ) {
			my $pos = $wagon->{positionamhalt};
			if (   $pos->{startprozent} eq ''
				or $pos->{endeprozent} eq ''
				or $pos->{startmeter} eq ''
				or $pos->{endemeter} eq '' )
			{
				return $self->{has_bad_wagons} = 1;
			}
		}
	}

	return $self->{has_bad_wagons} = 0;
}

sub origins {
	my ($self) = @_;

	if ( exists $self->{origins} ) {
		return @{ $self->{origins} };
	}

	my @origins;

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		push( @origins, $group->{startbetriebsstellename} );
	}

	@origins = uniq @origins;

	$self->{origins} = \@origins;

	return @origins;
}

sub destinations {
	my ($self) = @_;

	if ( exists $self->{destinations} ) {
		return @{ $self->{destinations} };
	}

	my @destinations;
	my %section;

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		my $destination = $group->{zielbetriebsstellename};
		my @sections = map { $_->{fahrzeugsektor} } @{ $group->{allFahrzeug} };
		@sections = uniq @sections;
		push( @{ $section{$destination} }, @sections );
		push( @destinations,               $destination );
	}

	@destinations = uniq @destinations;

	@destinations
	  = map { { name => $_, sections => $section{$_} } } @destinations;

	$self->{destinations} = \@destinations;

	return @destinations;
}

sub platform {
	my ($self) = @_;

	return $self->{data}{istformation}{halt}{gleisbezeichnung};
}

sub sections {
	my ($self) = @_;

	if ( exists $self->{sections} ) {
		return @{ $self->{sections} };
	}

	for my $section ( @{ $self->{data}{istformation}{halt}{allSektor} } ) {
		my $pos = $section->{positionamgleis};
		if ( $pos->{startprozent} eq '' or $pos->{endeprozent} eq '' ) {
			next;
		}
		push(
			@{ $self->{sections} },
			Travel::Status::DE::DBWagenreihung::Section->new(
				name          => $section->{sektorbezeichnung},
				start_percent => $pos->{startprozent},
				end_percent   => $pos->{endeprozent},
				start_meters  => $pos->{startmeter},
				end_meters    => $pos->{endemeter},
			)
		);
	}

	return @{ $self->{sections} // [] };
}

sub station_ds100 {
	my ($self) = @_;

	return $self->{data}{istformation}{halt}{rl100};
}

sub station_name {
	my ($self) = @_;

	return $self->{data}{istformation}{halt}{bahnhofsname};
}

sub station_uic {
	my ($self) = @_;

	return $self->{data}{istformation}{halt}{evanummer};
}

sub train_type {
	my ($self) = @_;

	return $self->{data}{istformation}{zuggattung};
}

sub train_numbers {
	my ($self) = @_;

	if ( exists $self->{train_numbers} ) {
		return @{ $self->{train_numbers} };
	}

	my @numbers;

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		push( @numbers, $group->{verkehrlichezugnummer} );
	}

	@numbers = uniq @numbers;

	$self->{train_numbers} = \@numbers;

	return @numbers;
}

sub train_no {
	my ($self) = @_;

	return $self->{data}{istformation}{zugnummer};
}

sub train_powertype {
	my ($self) = @_;

	if ( exists $self->{train_powertype} ) {
		return $self->{train_powertype};
	}

	my @wagons = $self->wagons;
	my %ml     = map { $_ => 0 } ( 90 .. 99 );

	for my $wagon (@wagons) {

		if ( not $wagon->uic_id or length( $wagon->uic_id ) != 12 ) {
			next;
		}

		my $wagon_type = substr( $wagon->uic_id, 0, 2 );
		if ( $wagon_type < 90 ) {
			next;
		}

		$ml{$wagon_type}++;
	}

	my @likelihood = reverse sort { $ml{$a} <=> $ml{$b} } keys %ml;

	if ( $ml{ $likelihood[0] } == 0 ) {
		return $self->{train_powertype} = undef;
	}

	return $self->{train_powertype} = $likelihood[0];
}

sub train_subtype {
	my ($self) = @_;

	if ( exists $self->{train_subtype} ) {
		return $self->{train_subtype};
	}

	my @wagons          = $self->wagons;
	my $with_restaurant = 0;

	my %ml = (
		'ICE 1'        => 0,
		'ICE 2'        => 0,
		'ICE 3 403.1'  => 0,
		'ICE 3 403.2'  => 0,
		'ICE 3 406'    => 0,
		'ICE 3 Velaro' => 0,
		'ICE 4'        => 0,
		'ICE T 411.1'  => 0,
		'ICE T 411.2'  => 0,
		'ICE T 415'    => 0,
		'IC2 Twindexx' => 0,
		'IC2 KISS'     => 0,
	);

	for my $wagon (@wagons) {
		if ( not $wagon->model ) {
			next;
		}
		if ( $wagon->type eq 'WRmz' ) {
			$with_restaurant = 1;
		}
		if ( $wagon->model == 401
			or ( $wagon->model >= 801 and $wagon->model <= 804 ) )
		{
			$ml{'ICE 1'}++;
		}
		elsif ( $wagon->model == 402
			or ( $wagon->model >= 805 and $wagon->model <= 808 ) )
		{
			$ml{'ICE 2'}++;
		}
		elsif ( $wagon->model == 403 and substr( $wagon->uic_id, 9, 2 ) <= 37 )
		{
			$ml{'ICE 3 403.1'}++;
		}
		elsif ( $wagon->model == 403 and substr( $wagon->uic_id, 9, 2 ) > 37 ) {
			$ml{'ICE 3 403.2'}++;
		}
		elsif ( $wagon->model == 406 ) {
			$ml{'ICE 3 406'}++;
		}
		elsif ( $wagon->model == 407 ) {
			$ml{'ICE 3 Velaro'}++;
		}
		elsif ( $wagon->model == 412 or $wagon->model == 812 ) {
			$ml{'ICE 4'}++;
		}
		elsif ( $wagon->model == 411 and substr( $wagon->uic_id, 9, 2 ) <= 32 )
		{
			$ml{'ICE T 411.1'}++;
		}
		elsif ( $wagon->model == 411 and substr( $wagon->uic_id, 9, 2 ) > 32 ) {
			$ml{'ICE T 411.2'}++;
		}
		elsif ( $wagon->model == 415 ) {
			$ml{'ICE T 415'}++;
		}
		elsif ( $wagon->model == 475 ) {
			$ml{'TGV'}++;
		}
		elsif ( $self->train_type eq 'IC' and $wagon->model == 110 ) {
			$ml{'IC2 KISS'}++;
		}
		elsif ( $self->train_type eq 'IC' and $wagon->is_dosto ) {
			$ml{'IC2 Twindexx'}++;
		}
	}

	my @likelihood = reverse sort { $ml{$a} <=> $ml{$b} } keys %ml;

	if ( $ml{ $likelihood[0] } <= 2 ) {

		# inconclusive
		return undef;
	}

	$self->{train_subtype} = $likelihood[0];

	if ( $self->{train_subtype} =~ m{ICE 3 4} and $with_restaurant ) {
		$self->{train_subtype} = 'ICE 3 Redesign';
	}
	return $self->{train_subtype};
}

sub wagons {
	my ($self) = @_;

	if ( exists $self->{wagons} ) {
		return @{ $self->{wagons} };
	}

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		for my $wagon ( @{ $group->{allFahrzeug} } ) {
			my $wagon_object
			  = Travel::Status::DE::DBWagenreihung::Wagon->new( %{$wagon},
				train_no => $group->{verkehrlichezugnummer} );
			push( @{ $self->{wagons} }, $wagon_object );
			if ( not $wagon_object->{position}{valid} ) {
				$self->{has_bad_wagons} = 1;
			}
		}
	}
	if ( @{ $self->{wagons} // [] } > 1 and not $self->has_bad_wagons ) {
		if ( $self->{wagons}[0]->{position}{start_percent}
			> $self->{wagons}[-1]->{position}{start_percent} )
		{
			$self->{direction} = 100;
		}
		else {
			$self->{direction} = 0;
		}
	}
	if ( not $self->has_bad_wagons ) {
		@{ $self->{wagons} } = sort {
			$a->{position}->{start_percent} <=> $b->{position}->{start_percent}
		} @{ $self->{wagons} };
	}

	# ->train_subtype calls ->wagons, so this call must not be made before
	# $self->{wagons} has beet set.
	my $tt = $self->train_subtype;

	if ($tt) {
		for my $wagon ( @{ $self->{wagons} } ) {
			$wagon->set_traintype($tt);
		}
	}

	return @{ $self->{wagons} // [] };
}

sub get_with_cache {
	my ( $self, $cache, $url ) = @_;

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

	my $ua  = $self->{user_agent};
	my $res = $ua->get($url);

	if ( $res->is_error ) {
		return ( undef, $res->status_line );
	}
	my $content = $res->decoded_content;

	if ($cache) {
		$cache->freeze( $url, \$content );
	}

	return ( $content, undef );
}

1;

__END__

=head1 NAME

Travel::Status::DE::DBWagenreihung - Interface to Deutsche Bahn Wagon Order API.

=head1 SYNOPSIS

    use Travel::Status::DE::DBWagenreihung;

    my $wr = Travel::Status::DE::DBWagenreihung->new(
        departure => 'DateTime or YYYYMMDDhhmm',
        train_number => 1234,
    );

    for my $wagon ( $wr->wagons ) {
        printf("Wagen %s: Abschnitt %s\n", $wagon->number // '?', $wagon->section);
    }

=head1 VERSION

version 0.05

This is beta software. The API may change without notice.

=head1 DESCRIPTION

Travel:Status:DE::DBWagenreihung is an unofficial interface to the Deutsche
Bahn Wagon Order API at L<https://www.apps-bahn.de/wr/wagenreihung/1.0>.  It
returns station-specific wagon orders for long-distance trains operated by
Deutsche Bahn. Data includes wagon positions on the platform, the ICE series,
wagon-specific attributes such as first/second class or family coaches, and the
internal type and number of each wagon.

Positions on the platform are given both in meters and per cent (relative to
platform length).

At the time of this writing, only ICE trains are officially supported by the
backend, and even then glitches may occur. IC/EC trains are not officially
supported; reported wagon orders may be correct, may lack unscheduled changes,
or may be completely bogus.

=head1 METHODS

=over

=item my $wr = Travel::Status::DE::DBWagenreihung->new(I<%opts>)

Requests wagon order for a specific train at a specific scheduled departure
time and date, which implicitly encodes the requested station. Use
L<Travel::Status::DE::IRIS> or similar to map station name and train number
to scheduled departure.

Arguments:

=over

=item B<departure> => I<datetime-obj> | I<YYYYMMDDhhmm>

Scheduled departure at the station of interested. Must be either a
L<DateTime> object or a string in YYYYMMDDhhmm format. Mandatory.

=item B<train_number> => I<number>

Train number. Do not include the train type: Use "8" for "EC 8" or
"100" for "ICE 100".

=back

=item $wr->destinations

Returns a list describing all final destinations of this train. In most
cases, it contains one element, however, for trains consisting of multiple
wings, it contains one element for each wing.

Each destination is a hash ref containing the destination B<name> and the
corresponding platform I<sections> (at the moment, this is a list of section
identifiers).

This function is subject to change.

=item $wr->direction

Gives the train's direction of travel. Returns 0 if the train will depart
towards position 0 and 100 if the train will depart towards the other platform
end (mnemonic: towards the 100% position).

=item $wr->errstr

In case of a fatal HTTP or backend error, returns a string describing it.
Returns undef otherwise.

=item $wr->origins

Returns a list of stations this train originates from. In most cases, this is
just one element; however, for trains consisting of multiple wings, it gives
the origin of each wing unless they are identical.

Each origin is a station name.

This function is subject to change.

=item $wr->platform

Returns the platform name.

=item $wr->sections

Describes the sections of the platform this train will depart from.
Returns a list of L<Travel::Status::DE::DBWagenreihung::Section> objects.

=item $wr->station_ds100

Returns the DS100 identifier of the requested station.

=item $wr->station_name

Returns the name of the requested station.

=item $wr->station_uic

Returns the international id (UIC ID / IBNR) of the requested station.

=item $wr->train_numbers

Returns the list of train numbers for this departure. In most cases, this is
just one element. For trains consisting of multiple wings (which typically have
different numbers), it contains one element for each wing.

=item $wr->train_type

Returns a string describing the train type, e.g. "ICE" or "IC".

=item $wr->train_subtype

Returns a string describing the rolling stock used for this train, e.g. "ICE 4"
or "IC2 KISS".

=item $wr->wagons

Describes the individual wagons the train consists of. Returns a list of
L<Travel::Status::DE::DBWagenreihung::Wagon> objects.

=back

=head1 DEPENDENCIES

=over

=item * L<JSON>

=item * L<LWP::UserAgent>

=back

=head1 BUGS AND LIMITATIONS

Many. This is beta software.

=head1 REPOSITORY

L<https://github.com/derf/Travel-Status-DE-DBWagenreihung>

=head1 AUTHOR

Copyright (C) 2018-2019 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
