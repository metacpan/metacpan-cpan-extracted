use Test::Most; 
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Tests::Mockery; Test::Pcuke::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Executor');
}

my $CLASS = 'Test::Pcuke::Executor';

new_ok( $CLASS => [], 'step runner instance');

can_ok( $CLASS, qw{execute add_definition destroy});

{ # add_definition()
	my $executor = $CLASS->new;
	
	throws_ok {
		$executor->add_definition( step_type => 'incorrect' );	
	} qr{incorrect step type}i, 'add_definition throws if given an incorrect step_type';
	
	throws_ok {
		$executor->add_definition( step_type => 'given' );	
	} qr{regexp required}i, 'add_definition throws if the capturing regexp is not given';

	lives_ok {
		foreach ( qw{given when then and but} ) {
			$executor->add_definition( step_type => $_, regexp => qr{^NO_MATCH$} );
		}
	} 'All correct step types added';
	
	$executor->destroy;
}

{ # execute
	my $step = omock('step', {
		title	=> 'step title',
	});
	
	my $executor = $CLASS->new;
	
	my $executed;
	
	$executor->add_definition(
		step_type	=> '*',
		regexp		=> qr{^no match$},
		code		=> sub {
			$executed = 0 unless defined $executed;
		}
	);

	$executor->add_definition(
		step_type	=> '*',
		regexp		=> qr{^step title$},
		code		=> sub {
			$executed = 1 unless defined $executed;
		}
	);

	$executor->add_definition(
		step_type	=> '*',
		regexp		=> qr{^no match$},
		code		=> sub {
			$executed = 0 unless defined $executed;
		}
	);

	my $result = $executor->execute($step);
	
	ok($executed, 'correct step definition is executed');
	is($result->status, 'pass', 'step is passed');

	$executor->destroy;
}

{
	cmock('step_failure');
	my $step = omock('step', { title => 'title'} );
	
	my $executor = $CLASS->new;
	$executor->add_definition(
		step_type	=> '*',
		regexp		=> qr{^title$},
		code		=> sub {
			die Test::Pcuke::Executor::StepFailure->new();
		}
	);
	
	
	my $result;
	
	lives_ok {
	 	$result = $executor->execute($step);
	} 'step failed step - not dies';
	
	is($result->status, 'fail', 'status of the failed step is fail');
	
	$executor->destroy;
}

{
	my $step = omock('step', { title => 'title'} );
	my $executor = $CLASS->new;
	my $result;
	
	lives_ok {
	 	$result = $executor->execute($step);
	} 'no defined steps - not dies';
	
	is($result->status, 'undef', 'undefineds step status is "undef"');
	
	$executor->destroy;
}


done_testing();
