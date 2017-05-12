use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Scenario');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Scenario';

new_ok($CLASS => [], 'scenario instance');
can_ok($CLASS, qw{title set_title add_step execute steps nsteps nscenarios});

{
	my $title = 'Scenario: title';
	my $scenario = $CLASS->new();

	$scenario->set_title($title);
	is($scenario->title, $title, 'set_title() sets title, title() returns title');

	throws_ok {
		$scenario->set_title("new $title");
	} qr{is an immutable property}, 'title is an immutable property';
}

{
	my $title = 'Scenario: title';
	my $scenario = $CLASS->new();
	is($scenario->title, q{}, 'if title is undefined, title() returns an empty string');

	$scenario->set_title();

	throws_ok {
		$scenario->set_title($title);
	} qr{is an immutable property}, 'Empty title is also immutable';

}

{	### add_step()
	
	my $count = 3;
	my @steps = ();
	my @statuses = qw{fail pass undef};
	my $nsteps = {fail=>0, undef=>0, pass=>0};

	my $scenario = $CLASS->new();

	foreach (0..$count) {
		my $status = $statuses[$_ % 3];
		$nsteps->{$status}++;
		$steps[$_] = omock('step', {
			status	=> $status,
		});
		
		$scenario->add_step( $steps[$_] );
	}

	$scenario->execute;

	foreach(0..$count) {
		is(metrics($steps[$_],'execute'),	1, "each step was executed");
	}

	is_deeply($scenario->steps, [ @steps ], "steps() returns steps");
	is_deeply($scenario->nsteps, $nsteps, "number of steps is calculated correctly");

}

{	### $CLASS->new( $conf )
	my $title = 'Scenario: title';
	my @steps = ();
	my $count = 3;
	
	foreach (0..$count) {
		$steps[$_] = omock('step');
	}

	my $scenario = $CLASS->new( {
		title	=> $title,
		steps	=> [ @steps ],
	} );

	is($scenario->title(), $title, 'title may be passed as an argument to the constructor');
	throws_ok {
		$scenario->set_title('');
	} qr{is an immutable property}, 'title is still immutable';

	$scenario->execute();

	foreach(0..$count) {
		is(metrics($steps[$_], 'execute'),	1, "each step is executed");
	}
}

{
	my $scenario = $CLASS->new();
	my @executions;
	
	my $background = omock('background', {
		execute	=> sub { push @executions, 'background' },
		nsteps	=> { fail=>0, pass=>1, undef=>1 }
	});
	my $s1 = omock('step', {
		execute	=> sub { push @executions, 'step' },
		status	=> 'fail',
	});
	my $s2 = omock('step', {
		execute	=> sub { push @executions, 'step' },
		status	=> 'undef',
	});
	
	$scenario->add_step($_) for($s1, $s2);
	
	$scenario->execute($background);
	
	is_deeply([@executions], [qw{background step step}], "background is executed before steps");
	is_deeply($scenario->nsteps, {pass=>1, undef=>2, fail=>1}, "correct number of steps");
	is_deeply($scenario->nscenarios, {pass=>0, undef=>0, fail=>1}, "if any of steps is failed, scenario is failed too");
}

done_testing();
