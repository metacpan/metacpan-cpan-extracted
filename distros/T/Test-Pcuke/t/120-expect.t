use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Tests::Mockery; Test::Pcuke::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Expectation');
}

my $CLASS = 'Test::Pcuke::Expectation';

new_ok( $CLASS => [], 'expectation instance');

can_ok( $CLASS, qw{is_defined is_a} );

{
	my $expectation = $CLASS->new;
	ok ( !$expectation->is_defined, 'is_defined fails if an object was not defined');
}

{
	my $expectation = $CLASS->new( 4 );
	ok ( $expectation->is_defined, 'is_defined pass if an object was not defined');
}


{
	my $expectation = $CLASS->new( $CLASS->new );
	ok(   $expectation->is_a( $CLASS ),				'is_a pass if the object is an instance of class');
	ok( ! $expectation->is_a( "${CLASS}::$CLASS" ),	'is_a fail if the object is not an instance of class');
}

{
	my $expectation = $CLASS->new( 4 );
	ok(   $expectation->equals(4), 'equals pass if object eq subject');
	ok( ! $expectation->equals(5), 'equals fail if object ne subject');
}

{
	cmock('step_failure');
	my $expectation = $CLASS->new( 4, {
		throw	=> 'Test::Pcuke::Executor::StepFailure'
	} );
	
	my $exception;
	{
		local $@;
		eval { $expectation->equals(5) };
		$exception = $@;
	}	
	
	isa_ok($exception, 'Test::Pcuke::Executor::StepFailure', 'correct exception class');
	is($exception, instance('step_failure'), 'expectation throws on failure if you ask');
	
	lives_ok {
		$expectation->equals(4);
	} 'correct equals expectation does not throw';

	
}


done_testing();

