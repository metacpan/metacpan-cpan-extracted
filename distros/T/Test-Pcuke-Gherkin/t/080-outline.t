use Test::Most;
use FindBin qw{$Bin};

BEGIN: {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );
	
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Outline');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Outline';

new_ok( $CLASS => [], 'outline instance');
can_ok( $CLASS, qw{
	add_examples	add_step	set_title	execute	
	examples		steps		title
	nsteps			nscenarios	
});

{
	my $outline = $CLASS->new;
	my $title = 'outline title';
	
	$outline->set_title($title);
	
	is($outline->title, $title, 'set_title() sets title');
	
	throws_ok {
		$outline->set_title("$title$title");
	} qr{immutable}, "title is immutable";
}

{
	my $title = 'outline title';
	
	my $step1 = omock('step');
	my $step2 = omock('step');
	
	my $ex1 = omock('scenarios');
	my $ex2 = omock('scenarios');
	
	my $outline = $CLASS->new( {
		title		=> $title,
		steps		=> [$step1, $step2],
		examples	=> [$ex1, $ex2],
	} );
	
	is($outline->title, $title, "title can be passed as a constructor argument");
	is_deeply($outline->steps, [$step1, $step2], "steps can be passed to the constructor");
	is_deeply($outline->examples, [$ex1, $ex2], "steps can be passed to the constructor");
}

{
	my $outline = $CLASS->new;

	my $step1 = omock('step');
	my $step2 = omock('step');

	my $ex1 = omock('scenarios', { 
		execute => sub {
			is_deeply($_[1], [$step1, $step2], "steps are passed to scenarios' execute()") 
		},
		nsteps		=> {pass=>0, fail=>0, undef=>0},
		nscenarios	=> {pass=>0, fail=>0, undef=>0},
	} );
	my $ex2 = omock('scenarios', {
		execute => sub {
			is_deeply($_[1], [$step1, $step2], "steps are passed to scenarios' execute()") 
		},
		nsteps		=> {pass=>0, fail=>0, undef=>0},
		nscenarios	=> {pass=>0, fail=>0, undef=>0},
	});
	
	$outline->add_step( $_ ) for ($step1, $step2);
	$outline->add_examples( $_ ) for ($ex1, $ex2);
	$outline->execute();
	
	is_deeply($outline->examples,	[$ex1, $ex2], "examples() returns a ref to an array of examples");
	is_deeply($outline->steps,		[$step1, $step2], "steps() returns the steps");
}

{
	my $executions;
	my $s1 = omock('scenarios', {
		execute	=> sub { push @$executions, $_[2] },	# $_[2] must be a background
		nsteps		=> {pass=>0, fail=>0, undef=>0},
		nscenarios	=> {pass=>0, fail=>0, undef=>0},
	});
	
	my $s2 = omock('scenarios', {
		execute	=> sub { push @$executions, $_[2] },	# $_[2] must be a background
		nsteps		=> {pass=>0, fail=>0, undef=>0},
		nscenarios	=> {pass=>0, fail=>0, undef=>0},	});
	
	my $background = omock('background');
	
	my $outline = $CLASS->new;
	$outline->add_examples( $_ ) for ($s1, $s2);
	
	$outline->execute($background);
	
	is_deeply($executions, [$background, $background], "background is passed to scenarios->execute");
}

{
	my $s1 = omock('scenarios', {
		nsteps		=> {pass=>10, fail=>2, undef=>14},
		nscenarios	=> {pass=>1, fail=>1, undef=>2}, 
	});
	my $s2 = omock('scenarios', {
		nsteps		=> {pass=>15, fail=>1, undef=>22},
		nscenarios	=> {pass=>5, fail=>1, undef=>4}, 
	});
	
	my $outline = $CLASS->new();
	
	$outline->add_examples($_) for ( $s1, $s2 );
	$outline->execute;
	
	is_deeply($outline->nsteps,		{pass=>25, fail=>3, undef=>36}, "number of steps is calculated correctly");
	is_deeply($outline->nscenarios, {pass=>6, fail=>2, undef=>6},   "number of scenarios is calculated correctly");
}

done_testing();