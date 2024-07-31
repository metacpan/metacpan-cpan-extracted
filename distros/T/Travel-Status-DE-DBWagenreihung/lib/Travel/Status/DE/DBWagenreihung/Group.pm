package Travel::Status::DE::DBWagenreihung::Group;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';
use List::Util qw(uniq);

our $VERSION = '0.15';

Travel::Status::DE::DBWagenreihung::Group->mk_ro_accessors(
	qw(train_no train_type description desc_short destination has_sectors model series start_percent end_percent)
);

# {{{ Rolling Stock Models

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
	'420'      => ['BR 420'],
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

sub new {
	my ( $obj, %opt ) = @_;

	my %json = %{ $opt{json} };

	my $ref = {
		carriages   => $opt{carriages},
		destination => $json{transport}{destination}{name},
		train_type  => $json{transport}{category},
		name        => $json{transport}{name},
		line        => $json{transport}{numberwline},
		train_no    => $json{transport}{number},
	};

	$ref->{train} = $ref->{train_type} . ' ' . $ref->{train_no};

	$ref->{sectors} = [
		uniq grep { defined }
		  map     { $_->{platformPosition}{sector} } @{ $json{vehicles} // [] }
	];
	if ( @{ $ref->{sectors} } ) {
		$ref->{has_sectors} = 1;
	}

	$ref->{start_percent} = $ref->{carriages}[0]->start_percent;
	$ref->{end_percent}   = $ref->{carriages}[-1]->end_percent;

	bless( $ref, $obj );

	$ref->parse_description;

	return $ref;
}

sub parse_powertype {
	my ($self) = @_;

	my %ml = map { $_ => 0 } ( 90 .. 99 );

	for my $carriage ( $self->carriages ) {

		if ( not $carriage->uic_id or length( $carriage->uic_id ) != 12 ) {
			next;
		}

		my $carriage_type = substr( $carriage->uic_id, 0, 2 );
		if ( $carriage_type < 90 ) {
			next;
		}

		$ml{$carriage_type}++;
	}

	my @likelihood = reverse sort { $ml{$a} <=> $ml{$b} } keys %ml;

	if ( $ml{ $likelihood[0] } == 0 ) {
		return;
	}

	$self->{powertype} = $likelihood[0];
}

sub parse_model {
	my ($self) = @_;

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
		'420'      => 0,
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

	my @carriages = $self->carriages;

	for my $carriage (@carriages) {
		if ( not $carriage->model ) {
			next;
		}
		if ( $carriage->model == 401
			or ( $carriage->model >= 801 and $carriage->model <= 804 ) )
		{
			$ml{'401'}++;
		}
		elsif ( $carriage->model == 402
			or ( $carriage->model >= 805 and $carriage->model <= 808 ) )
		{
			$ml{'402'}++;
		}
		elsif ( $carriage->model == 403
			and substr( $carriage->uic_id, 9, 2 ) <= 37 )
		{
			$ml{'403.S1'}++;
		}
		elsif ( $carriage->model == 403
			and substr( $carriage->uic_id, 9, 2 ) > 37 )
		{
			$ml{'403.S2'}++;
		}
		elsif ( $carriage->model == 406 ) {
			$ml{'406'}++;
		}
		elsif ( $carriage->model == 407 ) {
			$ml{'407'}++;
		}
		elsif ( $carriage->model == 408 ) {
			$ml{'408'}++;
		}
		elsif ( $carriage->model == 412 or $carriage->model == 812 ) {
			$ml{'412'}++;
		}
		elsif ( $carriage->model == 411
			and substr( $carriage->uic_id, 9, 2 ) <= 32 )
		{
			$ml{'411.S1'}++;
		}
		elsif ( $carriage->model == 411
			and substr( $carriage->uic_id, 9, 2 ) > 32 )
		{
			$ml{'411.S2'}++;
		}
		elsif ( $carriage->model == 415 ) {
			$ml{'415'}++;
		}
		elsif ( $carriage->model == 420 or $carriage->model == 421 ) {
			$ml{'420'}++;
		}
		elsif ( $carriage->model == 422 or $carriage->model == 432 ) {
			$ml{'422'}++;
		}
		elsif ( $carriage->model == 423 or $carriage->model == 433 ) {
			$ml{'423'}++;
		}
		elsif ( $carriage->model == 425 or $carriage->model == 435 ) {
			$ml{'425'}++;
		}
		elsif ( $carriage->model == 427 or $carriage->model == 827 ) {
			$ml{'427'}++;
		}
		elsif ( $carriage->model == 428 or $carriage->model == 828 ) {
			$ml{'428'}++;
		}
		elsif ( $carriage->model == 429 or $carriage->model == 829 ) {
			$ml{'429'}++;
		}
		elsif ( $carriage->model == 430 or $carriage->model == 431 ) {
			$ml{'430'}++;
		}
		elsif ($carriage->model == 440
			or $carriage->model == 441
			or $carriage->model == 841 )
		{
			$ml{'440'}++;
		}
		elsif ($carriage->model == 442
			or $carriage->model == 443 )
		{
			$ml{'442'}++;
		}
		elsif ($carriage->model == 462
			or $carriage->model == 862 )
		{
			$ml{'462'}++;
		}
		elsif ($carriage->model == 463
			or $carriage->model == 863 )
		{
			$ml{'463'}++;
		}
		elsif ( $carriage->model == 445 ) {
			$ml{'445'}++;
		}
		elsif ( $carriage->model == 446 ) {
			$ml{'446'}++;
		}
		elsif ( $carriage->model == 475 ) {
			$ml{'475'}++;
		}
		elsif ( $carriage->model == 612 ) {
			$ml{'612'}++;
		}
		elsif ( $carriage->model == 620 or $carriage->model == 621 ) {
			$ml{'620'}++;
		}
		elsif ( $carriage->model == 622 ) {
			$ml{'622'}++;
		}
		elsif ( $carriage->model == 631 ) {
			$ml{'631'}++;
		}
		elsif ( $carriage->model == 632 ) {
			$ml{'632'}++;
		}
		elsif ( $carriage->model == 633 ) {
			$ml{'633'}++;
		}
		elsif ( $carriage->model == 640 ) {
			$ml{'640'}++;
		}
		elsif ( $carriage->model == 642 ) {
			$ml{'642'}++;
		}
		elsif ( $carriage->model == 643 or $carriage->model == 943 ) {
			$ml{'643'}++;
		}
		elsif ( $carriage->model == 648 ) {
			$ml{'648'}++;
		}
		elsif ( $self->train_type eq 'IC' and $carriage->model == 110 ) {
			$ml{'IC2.KISS'}++;
		}
		elsif ( $self->train_type eq 'IC' and $carriage->is_dosto ) {
			$ml{'IC2.TWIN'}++;
		}
		elsif ( substr( $carriage->uic_id, 4, 4 ) eq '4011' ) {
			$ml{'011'}++;
		}
	}

	my @likelihood = reverse sort { $ml{$a} <=> $ml{$b} } keys %ml;

	# Less than two carriages are generally inconclusive.
	# Exception: BR 631 (Link I) only has a single carriage
	if (
		$ml{ $likelihood[0] } < 2
		and not($likelihood[0] eq '631'
			and @carriages == 1
			and substr( $carriages[0]->uic_id, 0, 2 ) eq '95' )
	  )
	{
		$self->{subtype} = undef;
	}
	else {
		$self->{subtype} = $likelihood[0];
	}

	if ( $self->{subtype} and $model_name{ $self->{subtype} } ) {
		my @model = @{ $model_name{ $self->{subtype} } };
		$self->{model}  = $model[0];
		$self->{series} = $model[-1];
	}
}

sub parse_description {
	my ($self) = @_;

	$self->parse_powertype;
	$self->parse_model;

	my $short;
	my $ret = q{};

	if ( $self->{model} ) {
		$short = $self->{model};
		$ret .= $self->{model};
	}

	if ( $self->{powertype} and $power_desc{ $self->{powertype} } ) {
		if ( not $ret and $power_desc{ $self->{powertype} } =~ m{^mit} ) {
			$ret = "Zug";
		}
		$ret .= ' ' . $power_desc{ $self->{powertype} };
		$short //= $ret;
		$short =~ s{elektrischer }{E-};
		$short =~ s{[Ll]\Kokomotive}{ok};
	}

	if ( $self->{series} and $self->{series} ne $self->{model} ) {
		$ret .= ' (' . $self->{series} . ')';
	}

	$self->{desc_short}  = $short;
	$self->{description} = $ret;
}

sub sectors {
	my ($self) = @_;

	return @{ $self->{sectors} // [] };
}

sub carriages {
	my ($self) = @_;

	return @{ $self->{carriages} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	return {%copy};
}

1;
