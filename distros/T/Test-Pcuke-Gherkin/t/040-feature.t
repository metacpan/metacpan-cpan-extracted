use Test::Most;

use FindBin qw{$Bin};

BEGIN: {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin 
	else { die "wrong Bin path!" }
	
	require lib; lib->import( "$Bin/lib" );
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
			
	use_ok('Test::Pcuke::Gherkin::Node::Feature');
}

my $class = 'Test::Pcuke::Gherkin::Node::Feature';

new_ok($class => [], 'feature instance');

can_ok($class, qw{
	new 		execute		nsteps			nscenarios 
	set_title	title		set_narrative	narrative
	set_background			background
	add_scenario			scenarios
});

{
	my $title = "feature title";
	my $feature = $class->new();

	$feature->set_title($title);

	is($feature->title, $title, 'set_title() sets the title, title() returns the title');

	throws_ok {
		$feature->set_title($title);
	} qr{is an immutable}i, 'set_title may be used only once';
}

{
	my $title = 'feature title';
	my $feature = $class->new();
	
	$feature->set_title;
	is($feature->title(), q{}, 'Undefined title becomes an empty string');

	throws_ok {
		$feature->set_title($title);
	} qr{is an immutable}i, 'empty title is immutable too';

}

{
	my $feature = $class->new();
	my $narrative = "this is a narrative";
	$feature->set_narrative($narrative);
	is($feature->narrative, $narrative, 'set_narrative() sets and narrative() gets the narrative');

	throws_ok {
		$feature->set_narrative(q{rubbish});
	} qr{is an immutable}i, 'set_narrative may be used only once';
}

{
	my $feature = $class->new();
	my $narrative = 'narrative';
	
	$feature->set_narrative;
	is($feature->narrative,q{},'undefined narrative means empty string');

	throws_ok {
		$feature->set_narrative($narrative);
	} qr{is an immutable}i, 'empty narrative is also immutable';
}

{
	my $feature = $class->new();
	is($feature->title, q{}, 'title() returns an empty string if title is not defined');
	is($feature->narrative, q{}, 'narrative() returns an empty string if narrative is not defined');
}

{
	my $feature = $class->new();
	throws_ok {
		$feature->add_scenario();
	} qr{scenario must be defined}, 'scenario must be defined';
}

{
	my $feature = $class->new();
	my $count = 3;
	my @scenarios = ();
	
	foreach(0..$count) {
		$scenarios[$_] = omock('scenario', { 
			nsteps		=> { pass=>0, undef=>0, fail=>0 },
			nscenarios	=> { pass=>0, undef=>0, fail=>0 },
		});
		$feature->add_scenario($scenarios[$_]);
	}

	$feature->execute();

	foreach(0..$count) {
		is( metrics($scenarios[$_], 'execute'), 1, "Every scenario in the feature was executed");
	}
}

{	## test that every property can be configured in new
	my $background = omock('background');
	my @scenarios = ();
	my ($count, $title, $narrative) = (3, 'title', 'narrative');
	
	
	foreach(0..$count) {
		$scenarios[$_] = omock('scenario', { 
			nsteps		=> { pass=>0, undef=>0, fail=>0 },
			nscenarios	=> { pass=>0, undef=>0, fail=>0 },
		});
	}

	my $feature = $class->new( {
		title		=> $title,
		narrative	=> $narrative,
		scenarios	=> [ @scenarios ],
		background	=> $background,
	} );

	is($feature->title, $title, 'title can be set as a constructor argument');
	is($feature->narrative, $narrative, 'narrative can be set as a constructor argument');

	$feature->execute();

	foreach(@scenarios) {
		is(metrics($_, 'execute'), 1, "Every scenario in the feature was executed");
	}
	
	is($feature->background, $background, "background can be passed to the costructor");
}

{
	my $feature = $class->new();
	my ($scenario1, $scenario2);

	$scenario1 = omock('scenario', { 
			nsteps		=> { pass=>10, undef=>5, fail=>9 },
			nscenarios	=> { pass=>0, undef=>0, fail=>0 },
		});
		
	$feature->add_scenario($scenario1);

	$scenario2 = omock('scenario', { 
			nsteps		=> { pass=>5, undef=>10, fail=>6 },
			nscenarios	=> { pass=>0, undef=>0, fail=>0 },
		} );
		
	$feature->add_scenario($scenario2);

	my $executed_feature = $feature->execute;

	is_deeply($feature->nsteps, {pass=>15, undef=>15, fail=>15}, "correct number of steps");

	is($executed_feature, $feature, 'execute() returns the self instance');

	my $scenarioses;
	lives_ok {
		$scenarioses = $feature->scenarios;
	} 'can query the scenarios';

	is_deeply($scenarioses, [$scenario1, $scenario2], 'correct scenarios returned by scenarios()');
}

{	### Background
	my $feature = $class->new();
	
	my $args;
	my $s1 = omock('scenario', {
		execute	=> sub { push @$args, $_[1]; },			# $_[1] must be a background 
		nsteps		=> { pass=>0, undef=>0, fail=>0 },
		nscenarios	=> { pass=>0, undef=>0, fail=>0 },
	});
	my $s2 = omock('scenario', {
		execute	=> sub { push @$args, $_[1]; },			# $_[1] must be a background
		nsteps		=> { pass=>0, undef=>0, fail=>0 },
		nscenarios	=> { pass=>0, undef=>0, fail=>0 },
	});
	
	my $bgr = omock('background');
	
	$feature->add_scenario( $_ ) for ($s1, $s2);
	$feature->set_background( $bgr );
	
	is($feature->background, $bgr, 'background returns a background object');
	
	$feature->execute();
	
	is(metrics($s1,'execute'), 1, "scenario 1 is executed");
	is(metrics($s2,'execute'), 1, "scenario 2 is executed");
	is_deeply($args, [$bgr, $bgr], "background is passed to scenario->execute()");
}

{	### outlines
	my $feature = $class->new();
	my $o1 = omock('outline',{
		nsteps		=> {pass => 1, fail => 2, undef => 3},
		nscenarios	=> {pass => 5, fail => 4, undef => 3}
	});
	my $o2 = omock('outline', {
		nsteps		=> {pass => 1, fail => 3, undef => 5},
		nscenarios	=> {pass => 1, fail => 2, undef => 3},
	} );
	
	$feature->add_outline( $_ ) for ( $o1, $o2 );
	$feature->execute();
	
	is( metrics($o1,'execute'), 1, "outline 1 is executed");
	is( metrics($o2,'execute'), 1, "outline 2 is executed");
	
	is_deeply( $feature->nsteps, { pass=>2, fail=>5, undef=>8 }, "correct number of steps");
	is_deeply( $feature->nscenarios, {pass=>6, fail=>6, undef=>6}, "correct number of scenarios" );
}


done_testing();
