#!/usr/bin/perl -Tw

use strict;
use warnings;

# use Test::More tests => 41;
use Test::Simple skip_all => "Deprecated";

use Weather::Google;

my $g = new Weather::Google(90210);

ok( $g->can('current_conditions'));
is( ref $g->current_conditions, 'HASH', "hash ref");

# Man page says we can get icon, temp_f, temp_c, wind_condition, humidity,
# and condition out of this.

my @test = ('icon', 'temp_f', 'temp_c', 'wind_condition', 'humidity',
	'condition' );

foreach my $t (@test) {
	my ($x,$y,$z);
	ok( $x = $g->current_conditions($t), "current_conditions($t)" );
	# current is an alias
	ok( $y = $g->current($t), "current($t)" );
	# And we should have alias...
	ok( $z = $g->$t, "$t as method" );
	is( $x, $y, "$x == $y");
	is( $x, $z, "$x == $z");
	is( $y, $z, "$y == $z");
}

# And we should be able to pass an array

my (@a,@b);
ok( @a = $g->current_conditions(@test) );
ok( @b = $g->current(@test) );
is( @a, @b, "Arrays work" );


