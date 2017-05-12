use Test::More 1.00;

my @classes = qw(Test::Prereq Test::Prereq::Build);

foreach my $class ( @classes ) {
	undef &main::prereq_ok;
	BAIL_OUT( "Could not compile $class!" ) unless use_ok( $class );
	ok( defined &main::prereq_ok, "prereq_ok imported" );
	}

done_testing();
