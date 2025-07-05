package Travel::Status::DE::DBRIS::Formation::Group;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';
use List::Util qw(uniq);

our $VERSION = '0.12';

Travel::Status::DE::DBRIS::Formation::Group->mk_ro_accessors(
	qw(designation name train_no train_type description desc_short destination has_sectors model series start_percent end_percent)
);

# {{{ ICE designations

# Courtesy of https://github.com/marudor/bahn.expert
# cat src/server/coachSequence/TrainNames.ts | perl -nE 'if (m{(\d+): ''([^'']+)''}) { say "$1 => ''$2''," }' | xclip -i

my %ice_name = (
	101  => 'Gießen',
	102  => 'Jever',
	103  => 'Neu-Isenburg',
	104  => 'Fulda',
	105  => 'Offenbach am Main',
	106  => 'Itzehoe',
	107  => 'Plattling',
	108  => 'Lichtenfels',
	110  => 'Gelsenkirchen',
	111  => 'Nürnberg',
	112  => 'Memmingen',
	113  => 'Frankenthal/Pfalz',
	114  => 'Friedrichshafen',
	115  => 'Regensburg',
	116  => 'Pforzheim',
	117  => 'Hof',
	119  => 'Osnabrück',
	120  => 'Lüneburg',
	152  => 'Hanau',
	153  => 'Neumünster',
	154  => 'Flensburg',
	155  => 'Rosenheim',
	156  => 'Heppenheim/Bergstraße',
	157  => 'Landshut',
	158  => 'Gütersloh',
	159  => 'Bad Oldesloe',
	160  => 'Mülheim an der Ruhr',
	161  => 'Bebra',
	162  => 'Geisenheim/Rheingau',
	166  => 'Gelnhausen',
	167  => 'Garmisch-Partenkirchen',
	168  => 'Crailsheim',
	169  => 'Worms',
	171  => 'Heusenstamm',
	172  => 'Aschaffenburg',
	173  => 'Basel',
	174  => 'Zürich',
	175  => 'Nürnberg',
	176  => 'Bremen',
	177  => 'Rendsburg',
	178  => 'Bremerhaven',
	180  => 'Castrop-Rauxel',
	181  => 'Interlaken',
	182  => 'Rüdesheim am Rhein',
	183  => 'Timmendorfer Strand',
	184  => 'Bruchsal',
	185  => 'Freilassing',
	186  => 'Chur',
	187  => 'Mühldorf a. Inn',
	188  => 'Hildesheim',
	190  => 'Ludwigshafen am Rhein',
	201  => 'Rheinsberg',
	202  => 'Wuppertal',
	203  => 'Cottbus/Chóśebuz',
	204  => 'Bielefeld',
	205  => 'Zwickau',
	206  => 'Magdeburg',
	207  => 'Stendal',
	208  => 'Bonn',
	209  => 'Riesa',
	210  => 'Fontanestadt Neuruppin',
	211  => 'Uelzen',
	212  => 'Potsdam',
	213  => 'Nauen',
	214  => 'Hamm (Westf.)',
	215  => 'Bitterfeld-Wolfen',
	216  => 'Dessau',
	217  => 'Bergen auf Rügen',
	218  => 'Braunschweig',
	219  => 'Hagen',
	220  => 'Meiningen',
	221  => 'Lübbenau/Spreewald',
	222  => 'Eberswalde',
	223  => 'Schwerin',
	224  => 'Saalfeld (Saale)',
	225  => 'Oldenburg (Oldb)',
	226  => 'Lutherstadt Wittenberg',
	227  => 'Ludwigslust',
	228  => 'Altenburg',
	229  => 'Templin',
	230  => 'Delitzsch',
	231  => 'Brandenburg an der Havel',
	232  => 'Frankfurt (Oder)',
	233  => 'Ulm',
	234  => 'Minden',
	235  => 'Görlitz',
	236  => 'Jüterbog',
	237  => 'Neustrelitz',
	238  => 'Saarbrücken',
	239  => 'Essen',
	240  => 'Bochum',
	241  => 'Bad Hersfeld',
	242  => 'Quedlinburg',
	243  => 'Bautzen/Budyšin',
	244  => 'Koblenz',
	301  => 'Freiburg im Breisgau',
	302  => 'Hansestadt Lübeck',
	303  => 'Dortmund',
	304  => 'München',
	305  => 'Baden-Baden',
	306  => 'Nördlingen',
	307  => 'Oberhausen',
	308  => 'Murnau am Staffelsee',
	309  => 'Aalen',
	310  => 'Wolfsburg',
	311  => 'Wiesbaden',
	312  => 'Montabaur',
	313  => 'Treuchtlingen',
	314  => 'Bergisch Gladbach',
	315  => 'Singen (Hohentwiel)',
	316  => 'Siegburg',
	317  => 'Recklinghausen',
	318  => 'Münster (Westf.)',
	319  => 'Duisburg',
	320  => 'Weil am Rhein',
	321  => 'Krefeld',
	322  => 'Solingen',
	323  => 'Schaffhausen',
	324  => 'Fürth',
	325  => 'Ravensburg',
	326  => 'Neunkirchen',
	327  => 'Siegen',
	328  => 'Aachen',
	330  => 'Göttingen',
	331  => 'Westerland/Sylt',
	332  => 'Augsburg',
	333  => 'Goslar',
	334  => 'Offenburg',
	335  => 'Konstanz',
	336  => 'Ingolstadt',
	337  => 'Stuttgart',
	351  => 'Herford',
	352  => 'Mönchengladbach',
	353  => 'Neu-Ulm',
	354  => 'Mittenwald',
	355  => 'Tuttlingen',
	357  => 'Esslingen am Neckar',
	358  => 'St. Ingbert',
	359  => 'Leverkusen',
	360  => 'Linz am Rhein',
	361  => 'Celle',
	362  => 'Schwerte (Ruhr)',
	363  => 'Weilheim i. OB',
	1101 => 'Neustadt an der Weinstraße',
	1102 => 'Neubrandenburg',
	1103 => 'Paderborn',
	1104 => 'Erfurt',
	1105 => 'Dresden',
	1107 => 'Pirna',
	1108 => 'Berlin',
	1109 => 'Güstrow',
	1110 => 'Naumburg (Saale)',
	1111 => 'Hansestadt Wismar',
	1112 => 'Freie und Hansestadt Hamburg',
	1113 => 'Hansestadt Stralsund',
	1117 => 'Erlangen',
	1118 => 'Plauen/Vogtland',
	1119 => 'Meißen',
	1125 => 'Arnstadt',
	1126 => 'Leipzig',
	1127 => 'Weimar',
	1128 => 'Reutlingen',
	1129 => 'Kiel',
	1130 => 'Jena',
	1131 => 'Trier',
	1132 => 'Wittenberge',
	1151 => 'Elsterwerda',
	1152 => 'Travemünde',
	1153 => 'Ilmenau',
	1154 => 'Sonneberg',
	1155 => 'Mühlhausen/Thüringen',
	1156 => 'Waren (Müritz)',
	1157 => 'Innsbruck',
	1158 => 'Falkenberg/Elster',
	1159 => 'Passau',
	1160 => 'Markt Holzkirchen',
	1161 => 'Andernach',
	1162 => 'Vaihingen an der Enz',
	1163 => 'Ostseebad Binz',
	1164 => 'Rödental',
	1165 => 'Bad Oeynhausen',
	1166 => 'Bingen am Rhein',
	1167 => 'Traunstein',
	1168 => 'Ellwangen',
	1169 => 'Tutzing',
	1170 => 'Prenzlau',
	1171 => 'Oschatz',
	1172 => 'Bamberg',
	1173 => 'Halle (Saale)',
	1174 => 'Hansestadt Warburg',
	1175 => 'Villingen-Schwenningen',
	1176 => 'Coburg',
	1177 => 'Rathenow',
	1178 => 'Ostseebad Warnemünde',
	1180 => 'Darmstadt',
	1181 => 'Horb am Neckar',
	1182 => 'Mainz',
	1183 => 'Oberursel (Taunus)',
	1184 => 'Kaiserslautern',
	1190 => 'Wien',
	1191 => 'Salzburg',
	1192 => 'Linz',
	1501 => 'Eisenach',
	1502 => 'Karlsruhe',
	1503 => 'Altenbeken',
	1504 => 'Heidelberg',
	1505 => 'Marburg/Lahn',
	1506 => 'Kassel',
	1520 => 'Gotha',
	1521 => 'Homburg/Saar',
	1522 => 'Torgau',
	1523 => 'Hansestadt Greifswald',
	1524 => 'Hansestadt Rostock',
	2853 => 'Nationalpark Sächsische Schweiz',
	2865 => 'Remstal',
	2868 => 'Nationalpark Niedersächsisches Wattenmeer',
	2871 => 'Leipziger Neuseenland',
	2874 => 'Oberer Neckar',
	2875 => 'Magdeburger Börde',
	4102 => 'Naturpark Schönbuch',
	4103 => 'Allgäu',
	4108 => 'Hegau',
	4111 => 'Gäu',
	4114 => 'Dresden Elbland',
	4117 => 'Mecklenburgische Ostseeküste',
	4601 => 'Europa/Europe',
	4602 => 'Euregio Maas-Rhein',
	4603 => 'Mannheim',
	4604 => 'Brussel/Bruxelles',
	4607 => 'Hannover',
	4610 => 'Frankfurt am Main',
	4651 => 'Amsterdam',
	4652 => 'Arnhem',
	4680 => 'Würzburg',
	4682 => 'Köln',
	4683 => 'Limburg an der Lahn',
	4684 => 'Forbach-Lorraine',
	4685 => 'Schwäbisch Hall',
	4712 => 'Dillingen a.d. Donau',
	4710 => 'Ansbach',
	4717 => 'Paris',
	4893 => 'Bodetal',
	4898 => 'Lahntal',
	8007 => 'Rheinland',
	8019 => 'Düsseldorf',
	8020 => 'Amsterdam',
	8022 => 'Waldecker Land',
	8029 => 'Europa/Europe',
	9006 => 'Martin Luther',
	9009 => 'Cottbus/Chóśebuz',
	9018 => 'Freistaat Bayern',
	9025 => 'Nordrhein-Westfalen',
	9026 => 'Zürichsee',
	9028 => 'Freistaat Sachsen',
	9041 => 'Baden-Württemberg',
	9046 => 'Female ICE',
	9050 => 'Metropole Ruhr',
	9202 => 'Schleswig-Holstein',
	9208 => 'Nationalpark Bayrischer Wald',
	9212 => 'Fan-Hauptstadt Hamburg',
	9234 => 'Ruhr',
	9237 => 'Spree',
	9457 => 'Bundesrepublik Deutschland',
	9481 => 'Rheinland-Pfalz'
);

# }}}

# {{{ Rolling Stock Models

my %model_name = (
	'011'      => [ 'ICE T',        'ÖBB 4011' ],
	'023'      => [ 'CFL KISS',     'CFL 2300' ],
	'401'      => [ 'ICE 1',        'BR 401' ],
	'402'      => [ 'ICE 2',        'BR 402' ],
	'403.S1'   => [ 'ICE 3',        'BR 403, 1. Serie' ],
	'403.S2'   => [ 'ICE 3',        'BR 403, 2. Serie' ],
	'403.R'    => [ 'ICE 3',        'BR 403 Redesign' ],
	'406'      => [ 'ICE 3',        'BR 406' ],
	'406.R'    => [ 'ICE 3',        'BR 406 Redesign' ],
	'407'      => [ 'ICE 3 Velaro', 'BR 407' ],
	'408'      => [ 'ICE 3neo',     'BR 408' ],
	'411.S1'   => [ 'ICE T',        'BR 411, 1. Serie' ],
	'411.S2'   => [ 'ICE T',        'BR 411, 2. Serie' ],
	'412'      => [ 'ICE 4',        'BR 412' ],
	'415'      => [ 'ICE T',        'BR 415' ],
	'420'      => ['BR 420'],
	'422'      => ['BR 422'],
	'423'      => ['BR 423'],
	'424'      => ['BR 424'],
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
	'563'      => [ 'Mireo Plus B',        'BR 563' ],
	'612'      => [ 'RegioSwinger',        'BR 612' ],
	'620'      => [ 'LINT 81',             'BR 620' ],
	'622'      => [ 'LINT 54',             'BR 622' ],
	'631'      => [ 'Link I',              'BR 631' ],
	'632'      => [ 'Link II',             'BR 632' ],
	'633'      => [ 'Link III',            'BR 633' ],
	'640'      => [ 'LINT 27',             'BR 640' ],
	'642'      => [ 'Desiro Classic',      'BR 642' ],
	'643'      => [ 'TALENT',              'BR 643' ],
	'644'      => [ 'TALENT',              'BR 644' ],
	'648'      => [ 'LINT 41',             'BR 648' ],
	'650'      => [ 'Regio-Shuttle RS1',   'BR 650' ],
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
		name        => $json{name},
		line        => $json{transport}{numberwline},
		train_no    => $json{transport}{number},
	};

	if ( $ref->{name} =~ m{ ^ IC[DE] 0* (\d+) $ }x and exists $ice_name{$1} ) {
		$ref->{designation} = $ice_name{$1};
	}

	$ref->{train} = $ref->{train_type} . ' ' . $ref->{train_no};

	$ref->{sectors} = [
		uniq grep { defined }
		  map { $_->{platformPosition}{sector} } @{ $json{vehicles} // [] }
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
		'023'      => 0,
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
		'424'      => 0,
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
		'563'      => 0,
		'612'      => 0,
		'620'      => 0,
		'622'      => 0,
		'631'      => 0,
		'632'      => 0,
		'633'      => 0,
		'640'      => 0,
		'642'      => 0,
		'643'      => 0,
		'644'      => 0,
		'648'      => 0,
		'650'      => 0,
		'IC2.TWIN' => 0,
		'IC2.KISS' => 0,
	);

	my @carriages = $self->carriages;

	for my $carriage (@carriages) {
		if ( not $carriage->model ) {
			next;
		}

		if ( $carriage->model == 023 ) {
			$ml{'023'}++;
		}
		elsif ( $carriage->model == 401
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
		elsif ( $carriage->model == 424 or $carriage->model == 434 ) {
			$ml{'424'}++;
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
		elsif ( $carriage->model == 563 ) {
			$ml{'563'}++;
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
		elsif ( $carriage->model == 644 or $carriage->model == 944 ) {
			$ml{'644'}++;
		}
		elsif ( $carriage->model == 648 ) {
			$ml{'648'}++;
		}
		elsif ( $carriage->model == 650 ) {
			$ml{'650'}++;
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
	# Exceptions: BR 631 (Link I), 640 (LINT 27, 650 (RS1)
	# only have a single carriage
	if (
		$ml{ $likelihood[0] } < 2
		and not(
			(
				   $likelihood[0] eq '631'
				or $likelihood[0] eq '640'
				or $likelihood[0] eq '650'
			)
			and @carriages == 1
			and substr( $carriages[0]->uic_id, 0, 2 ) eq '95'
		)
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

sub name_to_designation {
	my ($self) = @_;

	return %ice_name;
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

