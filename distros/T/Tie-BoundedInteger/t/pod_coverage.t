use Test::More 0.95;
eval "use Test::Pod::Coverage";

if( $@ ) {
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else {
	pod_coverage_ok( "Tie::BoundedInteger",
		{ trustme => [ qr/^[A-Z_]+$/ ] }
		);      
	}

done_testing();
