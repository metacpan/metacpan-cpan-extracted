#!/usr/bin/perl -Tw

use strict;
use warnings;

use Weather::Google;

# use Test::More;
use Test::Simple skip_all => "Deprecated";

# There are 5+3(n)+(3*11)(n) tests. 

my $g = new Weather::Google(90210);
my $num_tests = $g->forecast_conditions;
$num_tests = @$num_tests;
$num_tests = 5+((3*$num_tests)+(5*14)*($num_tests));
plan(tests => $num_tests);

ok( $g->can('forecast_conditions'));
is( ref $g->forecast_conditions, 'ARRAY', "Array ref");

# We can only (confidently) pass numbers that exist in the array.
my ($f,$n);
ok( $f = $g->forecast_conditions );
ok( $n = @$f );
ok( $n > 0, "Has ".($n+1)." values.");

for ( my $m=0; $m<$n; $m++ ) {

	# Man page says we can get icon, high, low, day_of_week, and condition for
	# each day out of this.

	my @test = ('icon', 'high', 'low', 'day_of_week', 'condition' );

	foreach my $t (@test) {
		my ($w, $x,$y,$z);
		# First check the hash
		ok( $w = $f->[$m]->{$t}, "$f -> [$m] -> {$t}" );
		ok( $x = $g->forecast_conditions($m,$t),
			"forecast_conditions($m,$t)" );
		# forecast is an alias
		ok( $y = $g->forecast($m,$t), "forecast($m,$t)" );
		# And we should have alias for day_of_week...
		my ($d,$dd,$e);
		ok( $d = $f->[$m]->{day_of_week} );
		# Test for the first three letters, and the full name
		my %days = (
			mon => 'monday',
			tue => 'tuesday',
			wed => 'wednesday',
			thu => 'thursday',
			fri => 'friday',
			sat => 'saturday',
			sun => 'sunday',
		);
		my $ld = lc($d);
		$dd = $d;
		$dd = $days{$ld} if exists $days{$ld};
		foreach my $ddd ($d,$dd) {
			ok( $e = $g->$ddd );
			is_deeply( $f->[$m], $e, "Alias $ddd is sane" );
			ok( $z = $g->$ddd($t), "$ddd($t)" );
		}
		is( $w, $x, "$w is $x");
		is( $x, $y, "$x is $y");
		is( $x, $z, "$x is $z");
		is( $y, $z, "$y is $z");
	}

	# And we should be able to pass an array

	my (@a,@b);
	ok( @a = $g->forecast_conditions($m,@test) );
	ok( @b = $g->forecast($m,@test) );
	is( @a, @b, "Arrays work" );
}

