#!/usr/bin/perl -Tw

use strict;
use warnings;

# use Test::More tests => 26;
use Test::Simple skip_all => "Deprecated";

use Weather::Google;

my $g = new Weather::Google(90210);

can_ok( $g, 'forecast_information');
is( ref $g->forecast_information, 'HASH', "hash ref");

# Man page says we can get these values:
my @test = ('forecast_date', 'current_date_time', 'city', 'postal_code',
	'unit_system', 'latitude_e6', 'longitude_e6' );

foreach my $t (@test) {
	my ($x,$y,$z);
TODO: {
	local $TODO = "Google hasn't implemented properly"
		if $t =~ /^.+?_e6$/;
	ok( $x = $g->forecast_information($t), "forecast_information($t)" );
	# info is an alias
	ok( $y = $g->info($t), "info($t)" );
}
	is( $x, $y, "$x == $y");
}

# And we should be able to pass an array

my (@a,@b);
ok( @a = $g->forecast_information(@test) );
ok( @b = $g->info(@test) );
is( @a, @b, "Arrays work" );


