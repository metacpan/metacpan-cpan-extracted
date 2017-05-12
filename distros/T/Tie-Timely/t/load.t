use Test::More 0.95;

my @classes = qw(Tie::Timely);

foreach my $class ( @classes ) {
	BAILOUT() unless use_ok( $class );
	}

done_testing;
