package Travel::Status::DE::DBWagenreihung;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

use Carp qw(cluck confess);
use JSON;
use List::Util qw(uniq);
use LWP::UserAgent;
use Travel::Status::DE::DBWagenreihung::Section;
use Travel::Status::DE::DBWagenreihung::Wagon;

our $VERSION = '0.13';

Travel::Status::DE::DBWagenreihung->mk_ro_accessors(
	qw(direction platform station train_no train_type));

# {{{ Rolling Stock Models

my %is_redesign = (
	"02" => 1,
	"03" => 1,
	"06" => 1,
	"09" => 1,
	"10" => 1,
	"13" => 1,
	"14" => 1,
	"15" => 1,
	"16" => 1,
	"18" => 1,
	"19" => 1,
	"20" => 1,
	"23" => 1,
	"24" => 1,
	"27" => 1,
	"28" => 1,
	"29" => 1,
	"31" => 1,
	"32" => 1,
	"33" => 1,
	"34" => 1,
	"35" => 1,
	"36" => 1,
	"37" => 1,
	"53" => 1
);

my %model_name = (
	'011'      => [ 'ICE T', 'ÖBB 4011' ],
	'401'      => ['ICE 1'],
	'402'      => ['ICE 2'],
	'403.S1'   => [ 'ICE 3',        'BR 403, 1. Serie' ],
	'403.S2'   => [ 'ICE 3',        'BR 403, 2. Serie' ],
	'403.R'    => [ 'ICE 3',        'BR 403 Redesign' ],
	'406'      => [ 'ICE 3',        'BR 406' ],
	'406.R'    => [ 'ICE 3',        'BR 406 Redesign' ],
	'407'      => [ 'ICE 3 Velaro', 'BR 407' ],
	'408'      => [ 'ICE 3neo',     'BR 408' ],
	'411.S1'   => [ 'ICE T',        'BR 411, 1. Serie' ],
	'411.S2'   => [ 'ICE T',        'BR 411, 2. Serie' ],
	'412'      => ['ICE 4'],
	'415'      => [ 'ICE T', 'BR 415' ],
	'422'      => ['BR 422'],
	'423'      => ['BR 423'],
	'425'      => ['BR 425'],
	'427'      => [ 'FLIRT', 'BR 427' ],
	'428'      => [ 'FLIRT', 'BR 428' ],
	'429'      => [ 'FLIRT', 'BR 429' ],
	'430'      => ['BR 430'],
	'440'      => [ 'Coradia Continental', 'BR 440' ],
	'442'      => [ 'Talent 2',            'BR 442' ],
	'445'      => [ 'Twindexx Vario',      'BR 445' ],
	'446'      => [ 'Twindexx Vario',      'BR 446' ],
	'462'      => [ 'Desiro HC',           'BR 462' ],
	'463'      => [ 'Mireo',               'BR 463' ],
	'475'      => [ 'TGV',                 'BR 475' ],
	'612'      => [ 'RegioSwinger',        'BR 612' ],
	'620'      => [ 'LINT 81',             'BR 620' ],
	'622'      => [ 'LINT 54',             'BR 622' ],
	'631'      => [ 'Link I',              'BR 631' ],
	'632'      => [ 'Link II',             'BR 632' ],
	'633'      => [ 'Link III',            'BR 633' ],
	'640'      => [ 'LINT 27',             'BR 640' ],
	'642'      => [ 'Desiro Classic',      'BR 642' ],
	'643'      => [ 'TALENT',              'BR 643' ],
	'648'      => [ 'LINT 41',             'BR 648' ],
	'IC2.TWIN' => ['IC 2 Twindexx'],
	'IC2.KISS' => ['IC 2 KISS'],
);

my %power_desc = (
	90 => 'mit sonstigem Antrieb',
	91 => 'mit elektrischer Lokomotive',
	92 => 'mit Diesellokomotive',
	93 => 'Hochgeschwindigkeitszug',
	94 => 'Elektrischer Triebzug',
	95 => 'Diesel-Triebzug',
	96 => 'mit speziellen Beiwagen',
	97 => 'mit elektrischer Rangierlok',
	98 => 'mit Diesel-Rangierlok',
	99 => 'Sonderfahrzeug',
);

# }}}
# {{{ Constructors

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
		  // 'https://ist-wr.noncd.db.de/wagenreihung/1.0',
		developer_mode => $opt{developer_mode},
		cache          => $opt{cache},
		departure      => $opt{departure},
		from_json      => $opt{from_json},
		json           => JSON->new,
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

	return $self->parse_wagonorder;
}

# }}}
# {{{ Internal Helpers

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

sub wagongroup_powertype {
	my ( $self, @wagons ) = @_;

	if ( not @wagons ) {
		@wagons = $self->wagons;
	}

	my %ml = map { $_ => 0 } ( 90 .. 99 );

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
		return undef;
	}

	return $likelihood[0];
}

sub parse_wagonorder {
	my ($self) = @_;

	$self->{platform} = $self->{data}{istformation}{halt}{gleisbezeichnung};

	$self->{station} = {
		ds100 => $self->{data}{istformation}{halt}{rl100},
		eva   => $self->{data}{istformation}{halt}{evanummer},
		name  => $self->{data}{istformation}{halt}{bahnhofsname},
	};

	$self->{train_type} = $self->{data}{istformation}{zuggattung};
	$self->{train_no}   = $self->{data}{istformation}{zugnummer};

	$self->parse_wagons;
	$self->{origins}      = $self->parse_wings('startbetriebsstellename');
	$self->{destinations} = $self->parse_wings('zielbetriebsstellename');
}

sub parse_wings {
	my ( $self, $attr ) = @_;

	my @names;
	my %section;

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		my $name     = $group->{$attr};
		my @sections = map { $_->{fahrzeugsektor} } @{ $group->{allFahrzeug} };
		push( @{ $section{$name} }, @sections );
		push( @names,               $name );
	}

	@names = uniq @names;

	@names
	  = map { { name => $_, sections => [ uniq @{ $section{$_} } ] } } @names;

	return \@names;
}

sub parse_wagons {
	my ($self) = @_;

	my @wagon_groups;

	for my $group ( @{ $self->{data}{istformation}{allFahrzeuggruppe} } ) {
		my @group;
		for my $wagon ( @{ $group->{allFahrzeug} } ) {
			my $wagon_object
			  = Travel::Status::DE::DBWagenreihung::Wagon->new( %{$wagon},
				train_no => $group->{verkehrlichezugnummer} );
			push( @{ $self->{wagons} }, $wagon_object );
			push( @group,               $wagon_object );
			if ( not $wagon_object->{position}{valid} ) {
				$self->{has_bad_wagons} = 1;
			}
		}
		push( @wagon_groups, [@group] );
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

	for my $i ( 0 .. $#wagon_groups ) {
		my $group = $wagon_groups[$i];
		my $tt    = $self->wagongroup_subtype( @{$group} );
		if ($tt) {
			for my $wagon ( @{$group} ) {
				$wagon->set_traintype( $i, $tt );
			}
		}
	}

	$self->{wagongroups} = [@wagon_groups];
}

# }}}
# {{{ Public Functions

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub destinations {
	my ($self) = @_;

	return @{ $self->{destinations} // [] };
}

sub origins {
	my ($self) = @_;

	return @{ $self->{origins} // [] };
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

sub train_descriptions {
	my ($self) = @_;

	if ( exists $self->{train_descriptions} ) {
		return @{ $self->{train_descriptions} };
	}

	for my $wagons ( @{ $self->{wagongroups} } ) {
		my ( $short, $desc ) = $self->wagongroup_description( @{$wagons} );
		my @sections = uniq map { $_->section } @{$wagons};

		push(
			@{ $self->{train_descriptions} },
			{
				sections => [@sections],
				short    => $short,
				text     => $desc,
			}
		);
	}

	return @{ $self->{train_descriptions} };
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

sub wagongroup_description {
	my ( $self, @wagons ) = @_;

	my $powertype = $self->wagongroup_powertype(@wagons);
	my @model     = $self->wagongroup_model(@wagons);

	my $short;
	my $ret = q{};

	if (@model) {
		$short = $model[0];
		$ret .= $model[0];
	}

	if ( $powertype and $power_desc{$powertype} ) {
		if ( not $ret and $power_desc{$powertype} =~ m{^mit} ) {
			$ret = "Zug";
		}
		$ret .= " $power_desc{$powertype}";
		$short //= $ret;
		$short =~ s{elektrischer }{E-};
		$short =~ s{[Ll]\Kokomotive}{ok};
	}

	if ( @model > 1 ) {
		$ret .= " ($model[1])";
	}

	return ( $short, $ret );
}

sub wagongroup_model {
	my ( $self, @wagons ) = @_;

	my $subtype = $self->wagongroup_subtype(@wagons);

	if ( $subtype and $model_name{$subtype} ) {
		return @{ $model_name{$subtype} };
	}
	if ($subtype) {
		return $subtype;
	}
	return;
}

sub wagongroup_subtype {
	my ( $self, @wagons ) = @_;

	if ( not @wagons ) {
		@wagons = $self->wagons;
	}

	my %ml = (
		'011'      => 0,
		'401'      => 0,
		'402'      => 0,
		'403.S1'   => 0,
		'403.S2'   => 0,
		'403.R'    => 0,
		'406'      => 0,
		'407'      => 0,
		'408'      => 0,
		'411.S1'   => 0,
		'411.S2'   => 0,
		'412'      => 0,
		'415'      => 0,
		'422'      => 0,
		'423'      => 0,
		'425'      => 0,
		'427'      => 0,
		'428'      => 0,
		'429'      => 0,
		'430'      => 0,
		'440'      => 0,
		'442'      => 0,
		'445'      => 0,
		'446'      => 0,
		'462'      => 0,
		'463'      => 0,
		'475'      => 0,
		'612'      => 0,
		'620'      => 0,
		'622'      => 0,
		'631'      => 0,
		'632'      => 0,
		'633'      => 0,
		'640'      => 0,
		'642'      => 0,
		'643'      => 0,
		'648'      => 0,
		'IC2.TWIN' => 0,
		'IC2.KISS' => 0,
	);

	for my $wagon (@wagons) {
		if ( not $wagon->model ) {
			next;
		}
		if ( $wagon->model == 401
			or ( $wagon->model >= 801 and $wagon->model <= 804 ) )
		{
			$ml{'401'}++;
		}
		elsif ( $wagon->model == 402
			or ( $wagon->model >= 805 and $wagon->model <= 808 ) )
		{
			$ml{'402'}++;
		}
		elsif ( $wagon->model == 403
			and $is_redesign{ substr( $wagon->uic_id, 9, 2 ) } )
		{
			$ml{'403.R'}++;
		}
		elsif ( $wagon->model == 403 and substr( $wagon->uic_id, 9, 2 ) <= 37 )
		{
			$ml{'403.S1'}++;
		}
		elsif ( $wagon->model == 403 and substr( $wagon->uic_id, 9, 2 ) > 37 ) {
			$ml{'403.S2'}++;
		}
		elsif ( $wagon->model == 406 ) {
			$ml{'406'}++;
		}
		elsif ( $wagon->model == 407 ) {
			$ml{'407'}++;
		}
		elsif ( $wagon->model == 408 ) {
			$ml{'408'}++;
		}
		elsif ( $wagon->model == 412 or $wagon->model == 812 ) {
			$ml{'412'}++;
		}
		elsif ( $wagon->model == 411 and substr( $wagon->uic_id, 9, 2 ) <= 32 )
		{
			$ml{'411.S1'}++;
		}
		elsif ( $wagon->model == 411 and substr( $wagon->uic_id, 9, 2 ) > 32 ) {
			$ml{'411.S2'}++;
		}
		elsif ( $wagon->model == 415 ) {
			$ml{'415'}++;
		}
		elsif ( $wagon->model == 422 or $wagon->model == 432 ) {
			$ml{'422'}++;
		}
		elsif ( $wagon->model == 423 or $wagon->model == 433 ) {
			$ml{'423'}++;
		}
		elsif ( $wagon->model == 425 or $wagon->model == 435 ) {
			$ml{'425'}++;
		}
		elsif ( $wagon->model == 427 or $wagon->model == 827 ) {
			$ml{'427'}++;
		}
		elsif ( $wagon->model == 428 or $wagon->model == 828 ) {
			$ml{'428'}++;
		}
		elsif ( $wagon->model == 429 or $wagon->model == 829 ) {
			$ml{'429'}++;
		}
		elsif ( $wagon->model == 430 or $wagon->model == 431 ) {
			$ml{'430'}++;
		}
		elsif ($wagon->model == 440
			or $wagon->model == 441
			or $wagon->model == 841 )
		{
			$ml{'440'}++;
		}
		elsif ($wagon->model == 442
			or $wagon->model == 443 )
		{
			$ml{'442'}++;
		}
		elsif ($wagon->model == 462
			or $wagon->model == 862 )
		{
			$ml{'462'}++;
		}
		elsif ($wagon->model == 463
			or $wagon->model == 863 )
		{
			$ml{'463'}++;
		}
		elsif ( $wagon->model == 445 ) {
			$ml{'445'}++;
		}
		elsif ( $wagon->model == 446 ) {
			$ml{'446'}++;
		}
		elsif ( $wagon->model == 475 ) {
			$ml{'475'}++;
		}
		elsif ( $wagon->model == 612 ) {
			$ml{'612'}++;
		}
		elsif ( $wagon->model == 620 or $wagon->model == 621 ) {
			$ml{'620'}++;
		}
		elsif ( $wagon->model == 622 ) {
			$ml{'622'}++;
		}
		elsif ( $wagon->model == 631 ) {
			$ml{'631'}++;
		}
		elsif ( $wagon->model == 632 ) {
			$ml{'632'}++;
		}
		elsif ( $wagon->model == 633 ) {
			$ml{'633'}++;
		}
		elsif ( $wagon->model == 640 ) {
			$ml{'640'}++;
		}
		elsif ( $wagon->model == 642 ) {
			$ml{'642'}++;
		}
		elsif ( $wagon->model == 643 or $wagon->model == 943 ) {
			$ml{'643'}++;
		}
		elsif ( $wagon->model == 648 ) {
			$ml{'648'}++;
		}
		elsif ( $self->train_type eq 'IC' and $wagon->model == 110 ) {
			$ml{'IC2.KISS'}++;
		}
		elsif ( $self->train_type eq 'IC' and $wagon->is_dosto ) {
			$ml{'IC2.TWIN'}++;
		}
		elsif ( substr( $wagon->uic_id, 4, 4 ) eq '4011' ) {
			$ml{'011'}++;
		}
	}

	my @likelihood = reverse sort { $ml{$a} <=> $ml{$b} } keys %ml;

	# Less than two wagons are generally inconclusive.
	# Exception: BR 631 (Link I) only has a single wagon
	if ( $ml{ $likelihood[0] } < 2 and $likelihood[0] ne '631' ) {
		return undef;
	}

	return $likelihood[0];
}

sub wagons {
	my ($self) = @_;
	return @{ $self->{wagons} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	# ensure that all objects are available
	$self->train_numbers;
	$self->train_descriptions;
	$self->sections;

	my %copy = %{$self};

	delete $copy{from_json};

	return {%copy};
}

# }}}

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

version 0.13

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

Returns a list describing the destinations of this train's wagons. In most
cases, it contains one element. For trains consisting of multiple wings or
trains that switch locomotives along the way, it contains one element for each
wing or other kind of wagon group.

Each destination is a hash ref containing its B<name> and the corresponding
platform I<sections> (at the moment, this is a list of section identifiers).

This function is subject to change.

=item $wr->direction

Gives the train's direction of travel. Returns 0 if the train will depart
towards position 0 and 100 if the train will depart towards the other platform
end (mnemonic: towards the 100% position).

=item $wr->errstr

In case of a fatal HTTP or backend error, returns a string describing it.
Returns undef otherwise.

=item $wr->origins

Returns a list describing the origins of this train's wagons. In most
cases, it contains one element. For trains consisting of multiple wings or
trains that switch locomotives along the way, it contains one element for each
wing or other kind of wagon group.

Each origin is a hash ref containing its B<name> and the corresponding
platform I<sections> (at the moment, this is a list of section identifiers).

This function is subject to change.

=item $wr->platform

Returns the platform name.

=item $wr->sections

Describes the sections of the platform this train will depart from.
Returns a list of L<Travel::Status::DE::DBWagenreihung::Section> objects.

=item $wr->station

Returns a hashref describing the requested station. The hashref contains three
entries: B<ds100> (DS100 / Ril100 identifier), B<eva> (EVA ID, related to but
not necessarily identical with UIC station ID), and B<name> (station name).

=item $wr->train_descriptions

Returns a list of hashes describing the rolling stock used for this train based
on model and locomotive (if present). Each hash contains the keys B<text>
(textual representation, see C<< $wr->train_desc >>) and B<sections>
(arrayref of corresponding sections).

=item $wr->wagongroup_description

Returns two strings describing the rolling stock used for this train based on
model and locomotive (if present). The first one tries to be conscise (e.g.
"ICE 4"). The second is more detailed, e.g. "ICE 4 Hochgeschwindigkeitszug",
"IC 2 Twindexx mit elektrischer Lokomotive", or "Diesel-Triebzug".

=item $wr->wagongroup_model

Returns a string describing the rolling stock used for this train, e.g. "ICE 4"
or "IC2 KISS".

=item $wr->train_numbers

Returns the list of train numbers for this departure. In most cases, this is
just one element. For trains consisting of multiple wings (which typically have
different numbers), it contains one element for each wing.

=item $wr->train_type

Returns a string describing the train type, e.g. "ICE" or "IC".

=item $wr->wagongroup_subtype

Returns a string describing the rolling stock model used for this train, e.g.
"412" (model 412 aka ICE 4) or "411.S2" (model 411 aka ICE T, series 2).

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

Copyright (C) 2018-2024 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
