use Test::More;
eval "use Test::Pod::Coverage";

if( $@ ) {
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else {
	pod_coverage_ok( "Test::Prereq" );

	pod_coverage_ok( "Test::Prereq::Build",
		{ trustme => [ qr/create_build_script|prereq_ok/ ] } );
	}

done_testing();
