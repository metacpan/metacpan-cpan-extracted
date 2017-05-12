use Test::Most;
use FindBin qw{$Bin};

BEGIN: {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );
	
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Scenarios');
}

my $CLASS="Test::Pcuke::Gherkin::Node::Scenarios";

new_ok( $CLASS => [], 'outline instance');

{
	my $scenarios = $CLASS->new();
	my $title = "title";
	
	$scenarios->set_title($title);
	is($scenarios->title, $title, "set_title() sets title");
}

{
	my $title = "title";
	my $table = omock('table');
	
	my $scenarios = $CLASS->new({
		title => $title,
		table => $table,
	});

	is($scenarios->title, $title, "title can be passed as a constructor argument");
	is($scenarios->table, $table, "table can be passed to a constructor");
}

{
	my $scenarios = $CLASS->new();
	my $step1 	= omock('step');
	my $step2 	= omock('step');
	
	my $background = omock('background');

	my $table	= omock('table', {
		execute	=> sub {
			is_deeply( $_[1], [$step1, $step2], "steps are passed to table->execute()");
			is($_[2], $background, "background is passed to table->execute");
		},
		nsteps		=> {pass=>6, fail=>7, undef=>8},
		nscenarios	=> {pass=>1, fail=>2, undef=>3},
	});
	
	$scenarios->set_table( $table );
	$scenarios->execute( [$step1, $step2], $background );
	
	is($scenarios->table, $table, 'talble() returns a table');
	is_deeply($scenarios->nsteps, {pass=>6, fail=>7, undef=>8}, "nsteps says what table->nsteps says");
	is_deeply($scenarios->nscenarios, {pass=>1, fail=>2, undef=>3}, "nscenarios says what table->nscenarios says");
}


done_testing();

