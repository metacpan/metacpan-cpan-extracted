#!/usr/bin/env perl

=pod

=head1 NAME

angular-sizes.pl - calculating the angular sizes of moons in the solar system

=head1 DESCRIPTION

Builds a collection of Star, Planet, and Moon objects to represent the
solar system, and finds moons which look approximately the same size as
the sun, when viewed from the surface of their planet.

Uses L<Zydeco::Lite>, L<Types::Standard>, and L<JSON::PP>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Z qw( decode_json );
use Math::Trig qw( asin pi );

my $JSON = do {
	local $/ = undef;
	decode_json( <DATA> );
};

my $app = app sub {
	
	my $CleanNumber = PositiveNum->plus_coercions(
		NonEmptyStr, sub {
			my ( $value ) = split /±/;
			$value =~ s/,//g;
			$value =~ s/^~//;
			$value =~ s/\s*//g;
			$value;
		},
	);
	
	role 'Body' => sub {
		
		requires 'parent';
		
		has 'children'       => (
			type        => 'ArrayRef[Body]',
			default     => sub { [] },
			handles_via => 'Array',
			handles     => [
				'adopt'            => 'push',
				'sorted_children'  => [ 'sort', sub { $_[0]->distance <=> $_[1]->distance } ],
				'find_child'       => 'first',
			],
		);
		
		has 'numeral'        => ( type => NonEmptyStr );
		has 'name'           => ( type => NonEmptyStr );
		has 'radius'         => ( type => $CleanNumber );
		has 'distance'       => ( type => $CleanNumber );             # dist from parent
		has 'angular_size'   => ( type => Maybe[PositiveNum], is => 'lazy' ); # size when seen from parent
		has 'angular_size_r' => ( type => Maybe[PositiveNum], is => 'lazy' ); # size of parent when seen from here
		
		method '_build_angular_size' => sub {
			my ( $self ) = ( shift );
			return 2 * asin( $self->radius / $self->distance ) * ( 180 / pi );
		};
		
		method '_build_angular_size_r' => sub {
			my ( $self ) = ( shift );
			return if is_Undef $self->parent;
			return if is_Undef $self->parent->radius;
			return 2 * asin( $self->parent->radius / $self->distance ) * ( 180 / pi );
		};
	};
	
	class 'Star' => sub {
		with 'Body';
		
		has 'parent'  => (
			type     => Any,
			default  => sub { undef },
			trigger  => sub {
				my ( $self, $parent ) = ( shift, @_ );
				$parent->adopt( $self ) if $self->FACTORY->type_library->get_type('Body')->check($parent);
				return $self;
			},
		);
		
		factory 'new_star', \'new';
		
		factory 'sol' => [] => sub {
			my ( $factory ) = ( shift );
			state $cached = do {
				my $sun = $factory->new_star( name => 'Sol', radius => '696340' );
				
				my %planet_lookup;
				foreach my $record ( @{ $JSON->{'planets'} } ) {
					my $planet = $factory->new_planet( %$record, parent => $sun );
					$planet_lookup{ $record->{'name'} } = $planet;
				}
				
				foreach my $record ( @{ $JSON->{'moons'} } ) {
					my $planet = $planet_lookup{ delete $record->{'parent'} };
					my $moon   = $factory->new_moon( %$record, parent => $planet );
				}
				
				$sun;
			};
		};
	};
	
	class 'Planet' => sub {
		# Technically these are not necessarily planets, but planet-like bodies.
		with 'Body';
		
		has 'parent'  => (
			type     => 'Star',
			trigger  => sub {
				my ( $self, $parent ) = ( shift, @_ );
				$parent->adopt( $self );
				return $self;
			},
			weak_ref => true,
		);
		
		coerce NonEmptyStr, 'from_name', sub {
			my ( $class, $name ) = @_;
			$class->FACTORY->sol->find_child(sub { lc($_[0]->name) eq lc($name) });
		};
		
		coerce HashRef, 'from_hashref' => sub {
			my ( $class, $hashref ) = ( shift, @_ );
			return $class->new( $hashref );
		};
	};
	
	class 'Moon' => sub {
		with 'Body';
		
		has 'parent'  => (
			type     => 'Planet',
			trigger  => sub {
				my ( $self, $parent ) = ( shift, @_ );
				$parent->adopt( $self );
				return $self;
			},
			weak_ref => true,
		);
		
		coerce HashRef, 'from_hashref' => sub {
			my ( $class, $hashref ) = ( shift, @_ );
			return $class->new( $hashref );
		};
	};
	
	my $tolerance = 1.1;
	
	method 'similar_numbers' => [ Maybe[Num], Maybe[Num] ] => sub {
		my ( $app, $x, $y ) = ( shift, @_ );
		return false unless is_Defined $x;
		return false unless is_Defined $y;
		return true if ( $x > $y/$tolerance and $x < $y*$tolerance );
		return true if ( $y > $x/$tolerance and $y < $x*$tolerance );
		return false;
	};
};

my $sun = $app->sol;

for my $planet ( $sun->sorted_children ) {
	for my $moon ( $planet->sorted_children ) {
		
		if ( $app->similar_numbers( $moon->angular_size, $planet->angular_size_r ) ) {
			printf(
				"From planet %s, moon %s looks %0.3f deg and %s looks %0.3f deg.\n",
				$planet->name,
				$moon->name,
				$moon->angular_size,
				$planet->parent->name,
				$planet->angular_size_r,
			);
		}
		
		if ( $app->similar_numbers( $moon->angular_size_r, $planet->angular_size_r ) ) {
			printf(
				"From moon %s, planet %s looks %0.3f deg and %s looks %0.3f deg.\n",
				$moon->name,
				$planet->name,
				$moon->angular_size_r,
				$planet->parent->name,
				$planet->angular_size_r,
			);
		}
	}
}

__DATA__
{
   "moons" : [
      {
         "distance" : "384399",
         "name" : "Luna",
         "numeral" : "I (1)",
         "parent" : "Earth",
         "radius" : "1737.1"
      },
      {
         "distance" : "9380",
         "name" : "Phobos",
         "numeral" : "I (1)",
         "parent" : "Mars",
         "radius" : "11.1"
      },
      {
         "distance" : "23460",
         "name" : "Deimos",
         "numeral" : "II (2)",
         "parent" : "Mars",
         "radius" : "6.2"
      },
      {
         "distance" : "421800",
         "name" : "Io",
         "numeral" : "I (1)",
         "parent" : "Jupiter",
         "radius" : "1818.1"
      },
      {
         "distance" : "671100",
         "name" : "Europa",
         "numeral" : "II (2)",
         "parent" : "Jupiter",
         "radius" : "1560.7"
      },
      {
         "distance" : "1070400",
         "name" : "Ganymede",
         "numeral" : "III (3)",
         "parent" : "Jupiter",
         "radius" : "2634.1"
      },
      {
         "distance" : "1882700",
         "name" : "Callisto",
         "numeral" : "IV (4)",
         "parent" : "Jupiter",
         "radius" : "2408.4"
      },
      {
         "distance" : "181400",
         "name" : "Amalthea",
         "numeral" : "V (5)",
         "parent" : "Jupiter",
         "radius" : "83.5"
      },
      {
         "distance" : "11461000",
         "name" : "Himalia",
         "numeral" : "VI (6)",
         "parent" : "Jupiter",
         "radius" : "67"
      },
      {
         "distance" : "11741000",
         "name" : "Elara",
         "numeral" : "VII (7)",
         "parent" : "Jupiter",
         "radius" : "43"
      },
      {
         "distance" : "23624000",
         "name" : "Pasiphae",
         "numeral" : "VIII (8)",
         "parent" : "Jupiter",
         "radius" : "30"
      },
      {
         "distance" : "23939000",
         "name" : "Sinope",
         "numeral" : "IX (9)",
         "parent" : "Jupiter",
         "radius" : "19"
      },
      {
         "distance" : "11717000",
         "name" : "Lysithea",
         "numeral" : "X (10)",
         "parent" : "Jupiter",
         "radius" : "18"
      },
      {
         "distance" : "23404000",
         "name" : "Carme",
         "numeral" : "XI (11)",
         "parent" : "Jupiter",
         "radius" : "23"
      },
      {
         "distance" : "21276000",
         "name" : "Ananke",
         "numeral" : "XII (12)",
         "parent" : "Jupiter",
         "radius" : "14"
      },
      {
         "distance" : "11165000",
         "name" : "Leda",
         "numeral" : "XIII (13)",
         "parent" : "Jupiter",
         "radius" : "10"
      },
      {
         "distance" : "221900",
         "name" : "Thebe",
         "numeral" : "XIV (14)",
         "parent" : "Jupiter",
         "radius" : "49.3"
      },
      {
         "distance" : "129000",
         "name" : "Adrastea",
         "numeral" : "XV (15)",
         "parent" : "Jupiter",
         "radius" : "8.2"
      },
      {
         "distance" : "128000",
         "name" : "Metis",
         "numeral" : "XVI (16)",
         "parent" : "Jupiter",
         "radius" : "21.5"
      },
      {
         "distance" : "24103000",
         "name" : "Callirrhoe",
         "numeral" : "XVII (17)",
         "parent" : "Jupiter",
         "radius" : "4.3"
      },
      {
         "distance" : "7284000",
         "name" : "Themisto",
         "numeral" : "XVIII (18)",
         "parent" : "Jupiter",
         "radius" : "4"
      },
      {
         "distance" : "23493000",
         "name" : "Megaclite",
         "numeral" : "XIX (19)",
         "parent" : "Jupiter",
         "radius" : "2.7"
      },
      {
         "distance" : "23280000",
         "name" : "Taygete",
         "numeral" : "XX (20)",
         "parent" : "Jupiter",
         "radius" : "2.5"
      },
      {
         "distance" : "23100000",
         "name" : "Chaldene",
         "numeral" : "XXI (21)",
         "parent" : "Jupiter",
         "radius" : "1.9"
      },
      {
         "distance" : "20858000",
         "name" : "Harpalyke",
         "numeral" : "XXII (22)",
         "parent" : "Jupiter",
         "radius" : "2.2"
      },
      {
         "distance" : "23483000",
         "name" : "Kalyke",
         "numeral" : "XXIII (23)",
         "parent" : "Jupiter",
         "radius" : "2.6"
      },
      {
         "distance" : "21060000",
         "name" : "Iocaste",
         "numeral" : "XXIV (24)",
         "parent" : "Jupiter",
         "radius" : "2.6"
      },
      {
         "distance" : "23196000",
         "name" : "Erinome",
         "numeral" : "XXV (25)",
         "parent" : "Jupiter",
         "radius" : "1.6"
      },
      {
         "distance" : "23155000",
         "name" : "Isonoe",
         "numeral" : "XXVI (26)",
         "parent" : "Jupiter",
         "radius" : "1.9"
      },
      {
         "distance" : "20908000",
         "name" : "Praxidike",
         "numeral" : "XXVII (27)",
         "parent" : "Jupiter",
         "radius" : "3.4"
      },
      {
         "distance" : "24046000",
         "name" : "Autonoe",
         "numeral" : "XXVIII (28)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "20939000",
         "name" : "Thyone",
         "numeral" : "XXIX (29)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "21131000",
         "name" : "Hermippe",
         "numeral" : "XXX (30)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "23229000",
         "name" : "Aitne",
         "numeral" : "XXXI (31)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "22865000",
         "name" : "Eurydome",
         "numeral" : "XXXII (32)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "20797000",
         "name" : "Euanthe",
         "numeral" : "XXXIII (33)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "19304000",
         "name" : "Euporie",
         "numeral" : "XXXIV (34)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "20720000",
         "name" : "Orthosie",
         "numeral" : "XXXV (35)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23487000",
         "name" : "Sponde",
         "numeral" : "XXXVI (36)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23217000",
         "name" : "Kale",
         "numeral" : "XXXVII (37)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23004000",
         "name" : "Pasithee",
         "numeral" : "XXXVIII (38)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23577000",
         "name" : "Hegemone",
         "numeral" : "XXXIX (39)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "21035000",
         "name" : "Mneme",
         "numeral" : "XL (40)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23980000",
         "name" : "Aoede",
         "numeral" : "XLI (41)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "21164000",
         "name" : "Thelxinoe",
         "numeral" : "XLII (42)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23355000",
         "name" : "Arche",
         "numeral" : "XLIII (43)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "23288000",
         "name" : "Kallichore",
         "numeral" : "XLIV (44)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "21069000",
         "name" : "Helike",
         "numeral" : "XLV (45)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "17058000",
         "name" : "Carpo",
         "numeral" : "XLVI (46)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "23328000",
         "name" : "Eukelade",
         "numeral" : "XLVII (47)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "23809000",
         "name" : "Cyllene",
         "numeral" : "XLVIII (48)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "24543000",
         "name" : "Kore",
         "numeral" : "XLIX (49)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "22983000",
         "name" : "Herse",
         "numeral" : "L (50)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23314335",
         "name" : "S/2010 J 1",
         "numeral" : "LI (51)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "20307150",
         "name" : "S/2010 J 2",
         "numeral" : "LII (52)",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "12570000",
         "name" : "Dia",
         "numeral" : "LIII (53)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "20595480",
         "name" : "S/2016 J 1",
         "numeral" : "LIV (54)",
         "parent" : "Jupiter",
         "radius" : "3"
      },
      {
         "distance" : "20426000",
         "name" : "S/2003 J 18",
         "numeral" : "LV (55)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23329710",
         "name" : "S/2011 J 2",
         "numeral" : "LVI (56)",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "23498000",
         "name" : "Eirene",
         "numeral" : "LVII (57)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "22630000",
         "name" : "Philophrosyne",
         "numeral" : "LVIII (58)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23483978",
         "name" : "S/2017 J 1",
         "numeral" : "LIX (59)",
         "parent" : "Jupiter",
         "radius" : "2"
      },
      {
         "distance" : "20224000",
         "name" : "Eupheme",
         "numeral" : "LX (60)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23535000",
         "name" : "S/2003 J 19",
         "numeral" : "LXI (61)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "18928095",
         "name" : "Valetudo",
         "numeral" : "LXII (62)",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "23240957",
         "name" : "S/2017 J 2",
         "numeral" : "LXIII (63)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "20639315",
         "name" : "S/2017 J 3",
         "numeral" : "LXIV (64)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "11494801",
         "name" : "Pandia",
         "numeral" : "LXV (65)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23169389",
         "name" : "S/2017 J 5",
         "numeral" : "LXVI (66)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "22394682",
         "name" : "S/2017 J 6",
         "numeral" : "LXVII (67)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "20571458",
         "name" : "S/2017 J 7",
         "numeral" : "LXVIII (68)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23174446",
         "name" : "S/2017 J 8",
         "numeral" : "LXIX (69)",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "21429955",
         "name" : "S/2017 J 9",
         "numeral" : "LXX (70)",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "11453004",
         "name" : "Ersa",
         "numeral" : "LXXI (71)",
         "parent" : "Jupiter",
         "radius" : "1.5"
      },
      {
         "distance" : "20155290",
         "name" : "S/2011 J 1",
         "numeral" : "LXXII (72)",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "28455000",
         "name" : "S/2003 J 2",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23933000",
         "name" : "S/2003 J 4",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23388000",
         "name" : "S/2003 J 9",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "23044000",
         "name" : "S/2003 J 10",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "17833000",
         "name" : "S/2003 J 12",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "0.5"
      },
      {
         "distance" : "20956000",
         "name" : "S/2003 J 16",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "23566000",
         "name" : "S/2003 J 23",
         "numeral" : "—",
         "parent" : "Jupiter",
         "radius" : "1"
      },
      {
         "distance" : "185540",
         "name" : "Mimas",
         "numeral" : "I (1)",
         "parent" : "Saturn",
         "radius" : "198.2"
      },
      {
         "distance" : "238040",
         "name" : "Enceladus",
         "numeral" : "II (2)",
         "parent" : "Saturn",
         "radius" : "252.3"
      },
      {
         "distance" : "294670",
         "name" : "Tethys",
         "numeral" : "III (3)",
         "parent" : "Saturn",
         "radius" : "536.3"
      },
      {
         "distance" : "377420",
         "name" : "Dione",
         "numeral" : "IV (4)",
         "parent" : "Saturn",
         "radius" : "562.5"
      },
      {
         "distance" : "527070",
         "name" : "Rhea",
         "numeral" : "V (5)",
         "parent" : "Saturn",
         "radius" : "764.5"
      },
      {
         "distance" : "1221870",
         "name" : "Titan",
         "numeral" : "VI (6)",
         "parent" : "Saturn",
         "radius" : "2575.5"
      },
      {
         "distance" : "1500880",
         "name" : "Hyperion",
         "numeral" : "VII (7)",
         "parent" : "Saturn",
         "radius" : "138.6"
      },
      {
         "distance" : "3560840",
         "name" : "Iapetus",
         "numeral" : "VIII (8)",
         "parent" : "Saturn",
         "radius" : "734.5"
      },
      {
         "distance" : "12947780",
         "name" : "Phoebe",
         "numeral" : "IX (9)",
         "parent" : "Saturn",
         "radius" : "106.6"
      },
      {
         "distance" : "151460",
         "name" : "Janus",
         "numeral" : "X (10)",
         "parent" : "Saturn",
         "radius" : "90.4"
      },
      {
         "distance" : "151410",
         "name" : "Epimetheus",
         "numeral" : "XI (11)",
         "parent" : "Saturn",
         "radius" : "58.3"
      },
      {
         "distance" : "377420",
         "name" : "Helene",
         "numeral" : "XII (12)",
         "parent" : "Saturn",
         "radius" : "16"
      },
      {
         "distance" : "294710",
         "name" : "Telesto",
         "numeral" : "XIII (13)",
         "parent" : "Saturn",
         "radius" : "12"
      },
      {
         "distance" : "294710",
         "name" : "Calypso",
         "numeral" : "XIV (14)",
         "parent" : "Saturn",
         "radius" : "9.5"
      },
      {
         "distance" : "137670",
         "name" : "Atlas",
         "numeral" : "XV (15)",
         "parent" : "Saturn",
         "radius" : "15.3"
      },
      {
         "distance" : "139380",
         "name" : "Prometheus",
         "numeral" : "XVI (16)",
         "parent" : "Saturn",
         "radius" : "46.8"
      },
      {
         "distance" : "141720",
         "name" : "Pandora",
         "numeral" : "XVII (17)",
         "parent" : "Saturn",
         "radius" : "40.6"
      },
      {
         "distance" : "133580",
         "name" : "Pan",
         "numeral" : "XVIII (18)",
         "parent" : "Saturn",
         "radius" : "12.8"
      },
      {
         "distance" : "23140400",
         "name" : "Ymir",
         "numeral" : "XIX (19)",
         "parent" : "Saturn",
         "radius" : "9"
      },
      {
         "distance" : "15200000",
         "name" : "Paaliaq",
         "numeral" : "XX (20)",
         "parent" : "Saturn",
         "radius" : "11"
      },
      {
         "distance" : "17983000",
         "name" : "Tarvos",
         "numeral" : "XXI (21)",
         "parent" : "Saturn",
         "radius" : "7.5"
      },
      {
         "distance" : "11124000",
         "name" : "Ijiraq",
         "numeral" : "XXII (22)",
         "parent" : "Saturn",
         "radius" : "6"
      },
      {
         "distance" : "19459000",
         "name" : "Suttungr",
         "numeral" : "XXIII (23)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "11110000",
         "name" : "Kiviuq",
         "numeral" : "XXIV (24)",
         "parent" : "Saturn",
         "radius" : "8"
      },
      {
         "distance" : "18628000",
         "name" : "Mundilfari",
         "numeral" : "XXV (25)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "16182000",
         "name" : "Albiorix",
         "numeral" : "XXVI (26)",
         "parent" : "Saturn",
         "radius" : "16"
      },
      {
         "distance" : "15540000",
         "name" : "Skathi",
         "numeral" : "XXVII (27)",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "17343000",
         "name" : "Erriapus",
         "numeral" : "XXVIII (28)",
         "parent" : "Saturn",
         "radius" : "5"
      },
      {
         "distance" : "18015400",
         "name" : "Siarnaq",
         "numeral" : "XXIX (29)",
         "parent" : "Saturn",
         "radius" : "20"
      },
      {
         "distance" : "20314000",
         "name" : "Thrymr",
         "numeral" : "XXX (30)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "19007000",
         "name" : "Narvi",
         "numeral" : "XXXI (31)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "194440",
         "name" : "Methone",
         "numeral" : "XXXII (32)",
         "parent" : "Saturn",
         "radius" : "1.6"
      },
      {
         "distance" : "212280",
         "name" : "Pallene",
         "numeral" : "XXXIII (33)",
         "parent" : "Saturn",
         "radius" : "2"
      },
      {
         "distance" : "377200",
         "name" : "Polydeuces",
         "numeral" : "XXXIV (34)",
         "parent" : "Saturn",
         "radius" : "1.25"
      },
      {
         "distance" : "136500",
         "name" : "Daphnis",
         "numeral" : "XXXV (35)",
         "parent" : "Saturn",
         "radius" : "3.8"
      },
      {
         "distance" : "20751000",
         "name" : "Aegir",
         "numeral" : "XXXVI (36)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "17119000",
         "name" : "Bebhionn",
         "numeral" : "XXXVII (37)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "19336000",
         "name" : "Bergelmir",
         "numeral" : "XXXVIII (38)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "20192000",
         "name" : "Bestla",
         "numeral" : "XXXIX (39)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "20377000",
         "name" : "Farbauti",
         "numeral" : "XL (40)",
         "parent" : "Saturn",
         "radius" : "2.5"
      },
      {
         "distance" : "22454000",
         "name" : "Fenrir",
         "numeral" : "XLI (41)",
         "parent" : "Saturn",
         "radius" : "2"
      },
      {
         "distance" : "25146000",
         "name" : "Fornjot",
         "numeral" : "XLII (42)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "19846000",
         "name" : "Hati",
         "numeral" : "XLIII (43)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "18437000",
         "name" : "Hyrrokkin",
         "numeral" : "XLIV (44)",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "22089000",
         "name" : "Kari",
         "numeral" : "XLV (45)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "23058000",
         "name" : "Loge",
         "numeral" : "XLVI (46)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "17665000",
         "name" : "Skoll",
         "numeral" : "XLVII (47)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "22704000",
         "name" : "Surtur",
         "numeral" : "XLVIII (48)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "197700",
         "name" : "Anthe",
         "numeral" : "XLIX (49)",
         "parent" : "Saturn",
         "radius" : "1"
      },
      {
         "distance" : "18811000",
         "name" : "Jarnsaxa",
         "numeral" : "L (50)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "18206000",
         "name" : "Greip",
         "numeral" : "LI (51)",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "18009000",
         "name" : "Tarqeq",
         "numeral" : "LII (52)",
         "parent" : "Saturn",
         "radius" : "3.5"
      },
      {
         "distance" : "167500",
         "name" : "Aegaeon",
         "numeral" : "LIII (53)",
         "parent" : "Saturn",
         "radius" : "0.33"
      },
      {
         "distance" : "20999000",
         "name" : "S/2004 S 7",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "19878000",
         "name" : "S/2004 S 12",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "2.5"
      },
      {
         "distance" : "18404000",
         "name" : "S/2004 S 13",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "19447000",
         "name" : "S/2004 S 17",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "2"
      },
      {
         "distance" : "18790000",
         "name" : "S/2006 S 1",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "22096000",
         "name" : "S/2006 S 3",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "16725000",
         "name" : "S/2007 S 2",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "18975000",
         "name" : "S/2007 S 3",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "117000",
         "name" : "S/2009 S 1",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "0.15"
      },
      {
         "distance" : "19418000",
         "name" : "S/2004 S 20",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "22645000",
         "name" : "S/2004 S 21",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "20636000",
         "name" : "S/2004 S 22",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "21163000",
         "name" : "S/2004 S 23",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "22901000",
         "name" : "S/2004 S 24",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "21174000",
         "name" : "S/2004 S 25",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "26676000",
         "name" : "S/2004 S 26",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "19976000",
         "name" : "S/2004 S 27",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "6"
      },
      {
         "distance" : "22020000",
         "name" : "S/2004 S 28",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "16981000",
         "name" : "S/2004 S 29",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "20396000",
         "name" : "S/2004 S 30",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "17568000",
         "name" : "S/2004 S 31",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "21214000",
         "name" : "S/2004 S 32",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "24168000",
         "name" : "S/2004 S 33",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "24299000",
         "name" : "S/2004 S 34",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "22412000",
         "name" : "S/2004 S 35",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "6"
      },
      {
         "distance" : "23192000",
         "name" : "S/2004 S 36",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "15892000",
         "name" : "S/2004 S 37",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "21908000",
         "name" : "S/2004 S 38",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "4"
      },
      {
         "distance" : "23575000",
         "name" : "S/2004 S 39",
         "numeral" : "—",
         "parent" : "Saturn",
         "radius" : "3"
      },
      {
         "distance" : "190900",
         "name" : "Ariel",
         "numeral" : "I (1)",
         "parent" : "Uranus",
         "radius" : "578.9"
      },
      {
         "distance" : "266000",
         "name" : "Umbriel",
         "numeral" : "II (2)",
         "parent" : "Uranus",
         "radius" : "584.7"
      },
      {
         "distance" : "436300",
         "name" : "Titania",
         "numeral" : "III (3)",
         "parent" : "Uranus",
         "radius" : "788.9"
      },
      {
         "distance" : "583500",
         "name" : "Oberon",
         "numeral" : "IV (4)",
         "parent" : "Uranus",
         "radius" : "761.4"
      },
      {
         "distance" : "129900",
         "name" : "Miranda",
         "numeral" : "V (5)",
         "parent" : "Uranus",
         "radius" : "235.8"
      },
      {
         "distance" : "49800",
         "name" : "Cordelia",
         "numeral" : "VI (6)",
         "parent" : "Uranus",
         "radius" : "20.1"
      },
      {
         "distance" : "53800",
         "name" : "Ophelia",
         "numeral" : "VII (7)",
         "parent" : "Uranus",
         "radius" : "21.4"
      },
      {
         "distance" : "59200",
         "name" : "Bianca",
         "numeral" : "VIII (8)",
         "parent" : "Uranus",
         "radius" : "25.7"
      },
      {
         "distance" : "61800",
         "name" : "Cressida",
         "numeral" : "IX (9)",
         "parent" : "Uranus",
         "radius" : "39.8"
      },
      {
         "distance" : "62700",
         "name" : "Desdemona",
         "numeral" : "X (10)",
         "parent" : "Uranus",
         "radius" : "32"
      },
      {
         "distance" : "64400",
         "name" : "Juliet",
         "numeral" : "XI (11)",
         "parent" : "Uranus",
         "radius" : "46.8"
      },
      {
         "distance" : "66100",
         "name" : "Portia",
         "numeral" : "XII (12)",
         "parent" : "Uranus",
         "radius" : "67.6"
      },
      {
         "distance" : "69900",
         "name" : "Rosalind",
         "numeral" : "XIII (13)",
         "parent" : "Uranus",
         "radius" : "36"
      },
      {
         "distance" : "75300",
         "name" : "Belinda",
         "numeral" : "XIV (14)",
         "parent" : "Uranus",
         "radius" : "40.3"
      },
      {
         "distance" : "86000",
         "name" : "Puck",
         "numeral" : "XV (15)",
         "parent" : "Uranus",
         "radius" : "81"
      },
      {
         "distance" : "7231100",
         "name" : "Caliban",
         "numeral" : "XVI (16)",
         "parent" : "Uranus",
         "radius" : "21"
      },
      {
         "distance" : "12179400",
         "name" : "Sycorax",
         "numeral" : "XVII (17)",
         "parent" : "Uranus",
         "radius" : "78.5"
      },
      {
         "distance" : "16256000",
         "name" : "Prospero",
         "numeral" : "XVIII (18)",
         "parent" : "Uranus",
         "radius" : "25"
      },
      {
         "distance" : "17418000",
         "name" : "Setebos",
         "numeral" : "XIX (19)",
         "parent" : "Uranus",
         "radius" : "24"
      },
      {
         "distance" : "8004000",
         "name" : "Stephano",
         "numeral" : "XX (20)",
         "parent" : "Uranus",
         "radius" : "10"
      },
      {
         "distance" : "8504000",
         "name" : "Trinculo",
         "numeral" : "XXI (21)",
         "parent" : "Uranus",
         "radius" : "9"
      },
      {
         "distance" : "4276000",
         "name" : "Francisco",
         "numeral" : "XXII (22)",
         "parent" : "Uranus",
         "radius" : "6"
      },
      {
         "distance" : "14345000",
         "name" : "Margaret",
         "numeral" : "XXIII (23)",
         "parent" : "Uranus",
         "radius" : "5.5"
      },
      {
         "distance" : "20901000",
         "name" : "Ferdinand",
         "numeral" : "XXIV (24)",
         "parent" : "Uranus",
         "radius" : "6"
      },
      {
         "distance" : "76417",
         "name" : "Perdita",
         "numeral" : "XXV (25)",
         "parent" : "Uranus",
         "radius" : "15"
      },
      {
         "distance" : "97736",
         "name" : "Mab",
         "numeral" : "XXVI (26)",
         "parent" : "Uranus",
         "radius" : "6"
      },
      {
         "distance" : "74392",
         "name" : "Cupid",
         "numeral" : "XXVII (27)",
         "parent" : "Uranus",
         "radius" : "9"
      },
      {
         "distance" : "354800",
         "name" : "Triton",
         "numeral" : "I (1)",
         "parent" : "Neptune",
         "radius" : "1353.4"
      },
      {
         "distance" : "5513820",
         "name" : "Nereid",
         "numeral" : "II (2)",
         "parent" : "Neptune",
         "radius" : "178.5"
      },
      {
         "distance" : "48224",
         "name" : "Naiad",
         "numeral" : "III (3)",
         "parent" : "Neptune",
         "radius" : "33"
      },
      {
         "distance" : "50075",
         "name" : "Thalassa",
         "numeral" : "IV (4)",
         "parent" : "Neptune",
         "radius" : "41"
      },
      {
         "distance" : "52526",
         "name" : "Despina",
         "numeral" : "V (5)",
         "parent" : "Neptune",
         "radius" : "75"
      },
      {
         "distance" : "61953",
         "name" : "Galatea",
         "numeral" : "VI (6)",
         "parent" : "Neptune",
         "radius" : "88"
      },
      {
         "distance" : "73548",
         "name" : "Larissa",
         "numeral" : "VII (7)",
         "parent" : "Neptune",
         "radius" : "97"
      },
      {
         "distance" : "117647",
         "name" : "Proteus",
         "numeral" : "VIII (8)",
         "parent" : "Neptune",
         "radius" : "210"
      },
      {
         "distance" : "15728000",
         "name" : "Halimede",
         "numeral" : "IX (9)",
         "parent" : "Neptune",
         "radius" : "31"
      },
      {
         "distance" : "46695000",
         "name" : "Psamathe",
         "numeral" : "X (10)",
         "parent" : "Neptune",
         "radius" : "20"
      },
      {
         "distance" : "22422000",
         "name" : "Sao",
         "numeral" : "XI (11)",
         "parent" : "Neptune",
         "radius" : "22"
      },
      {
         "distance" : "23571000",
         "name" : "Laomedeia",
         "numeral" : "XII (12)",
         "parent" : "Neptune",
         "radius" : "21"
      },
      {
         "distance" : "48387000",
         "name" : "Neso",
         "numeral" : "XIII (13)",
         "parent" : "Neptune",
         "radius" : "30"
      },
      {
         "distance" : "105283",
         "name" : "Hippocamp",
         "numeral" : "XIV (14)",
         "parent" : "Neptune",
         "radius" : "17.4"
      },
      {
         "distance" : "9000",
         "name" : "Vanth",
         "numeral" : "I (1)",
         "parent" : "Orcus",
         "radius" : "221"
      },
      {
         "distance" : "19591",
         "name" : "Charon",
         "numeral" : "I (1)",
         "parent" : "Pluto",
         "radius" : "606"
      },
      {
         "distance" : "48671",
         "name" : "Nix",
         "numeral" : "II (2)",
         "parent" : "Pluto",
         "radius" : "19.3"
      },
      {
         "distance" : "64698",
         "name" : "Hydra",
         "numeral" : "III (3)",
         "parent" : "Pluto",
         "radius" : "19.5"
      },
      {
         "distance" : "57729",
         "name" : "Kerberos",
         "numeral" : "IV (4)",
         "parent" : "Pluto",
         "radius" : "6.3"
      },
      {
         "distance" : "42393",
         "name" : "Styx",
         "numeral" : "V (5)",
         "parent" : "Pluto",
         "radius" : "5.5"
      },
      {
         "distance" : "5724",
         "name" : "Actaea",
         "numeral" : "I (1)",
         "parent" : "Salacia",
         "radius" : "142"
      },
      {
         "distance" : "49880",
         "name" : "Hiʻiaka",
         "numeral" : "I (1)",
         "parent" : "Haumea",
         "radius" : "160"
      },
      {
         "distance" : "25657",
         "name" : "Namaka",
         "numeral" : "II (2)",
         "parent" : "Haumea",
         "radius" : "85"
      },
      {
         "distance" : "14500",
         "name" : "Weywot",
         "numeral" : "I (1)",
         "parent" : "Quaoar",
         "radius" : "85"
      },
      {
         "distance" : "21000",
         "name" : "S/2015 (136472) 1",
         "numeral" : "—",
         "parent" : "Makemake",
         "radius" : "87.5"
      },
      {
         "distance" : "4809",
         "name" : "Ilmarë",
         "numeral" : "I (1)",
         "parent" : "Varda",
         "radius" : "163"
      },
      {
         "distance" : "24020",
         "name" : "Xiangliu",
         "numeral" : "I (1)",
         "parent" : "Gonggong",
         "radius" : "50"
      },
      {
         "distance" : "37370",
         "name" : "Dysnomia",
         "numeral" : "I (1)",
         "parent" : "Eris",
         "radius" : "350"
      }
   ],
   "planets" : [
      {
         "distance" : "57,909,175",
         "name" : "Mercury",
         "radius" : "2,439.64"
      },
      {
         "distance" : "108,208,930",
         "name" : "Venus",
         "radius" : "6,051.59"
      },
      {
         "distance" : "149,597,890",
         "name" : "Earth",
         "radius" : "6,378.10"
      },
      {
         "distance" : "227,936,640",
         "name" : "Mars",
         "radius" : "3,397.00"
      },
      {
         "distance" : "413,700,000",
         "name" : "Ceres",
         "radius" : "473.00"
      },
      {
         "distance" : "778,412,010",
         "name" : "Jupiter",
         "radius" : "71,492.68"
      },
      {
         "distance" : "1,426,725,400",
         "name" : "Saturn",
         "radius" : "60,267.14"
      },
      {
         "distance" : "2,870,972,200",
         "name" : "Uranus",
         "radius" : "25,557.25"
      },
      {
         "distance" : "4,498,252,900",
         "name" : "Neptune",
         "radius" : "24,766.36"
      },
      {
         "distance" : "5,896,946,000",
         "name" : "Orcus",
         "radius" : "458.50"
      },
      {
         "distance" : "5,906,380,000",
         "name" : "Pluto",
         "radius" : "1,187.00"
      },
      {
         "distance" : "6,310,600,000",
         "name" : "Salacia",
         "radius" : "423.00"
      },
      {
         "distance" : "6,484,000,000",
         "name" : "Haumea",
         "radius" : "816.00"
      },
      {
         "distance" : "6,535,930,000",
         "name" : "Quaoar",
         "radius" : "560.50"
      },
      {
         "distance" : "6,850,000,000",
         "name" : "Makemake",
         "radius" : "715.00"
      },
      {
         "distance" : "7,105,900,000",
         "name" : "Varda",
         "radius" : "750.00"
      },
      {
         "distance" : "10,072,433,340",
         "name" : "Gonggong",
         "radius" : "615.00"
      },
      {
         "distance" : "10,210,000,000",
         "name" : "Eris",
         "radius" : "1,163.00"
      },
      {
         "distance" : "78,668,000,000",
         "name" : "Sedna",
         "radius" : "497.50"
      }
   ]
}
