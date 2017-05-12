use Test::More 0.95;
my @classes = qw(Test::ISBN);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT();
	}

done_testing();
