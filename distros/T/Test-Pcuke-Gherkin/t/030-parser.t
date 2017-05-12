use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Parser');
}

my $CLASS = 'Test::Pcuke::Gherkin::Parser';

new_ok($CLASS=>[], 'parser instance');

{
	cmock_everything();
	
	my $tokens = get_tokens();
	my $executor = omock('executor');
	
	my $parser = $CLASS->new({ executor => $executor });
	my $feature = $parser->parse( $tokens );
	
	my $i = 0;
	my $passed = 1;
	while ( my $step = instance('step', $i) ) {
		$passed = 0 if $step->executor != $executor;
		$i++;
	}
	
	ok($passed, 'executor is passed to the step constructor');
}

{
	cmock_everything();
	my $tokens = get_tokens();
	my $parser = $CLASS->new;
	my $feature = $parser->parse( $tokens );
	
	is($feature, instance('feature'), "tree is a feature");
	is_deeply($feature->tags, ['@name1', '@name2'], "tags are ok");
		
	is($feature->title, 'Feature: feature title', "feature title ok");
	
	is($feature->narrative, "line1\nline2", "narrative is ok");
	
	my $scenarios = $feature->scenarios;
	is_deeply($scenarios, [
		instance('scenario',0),
		instance('scenario',1),
		instance('outline',0)
	], "scenarios are ok" );
	
	is($scenarios->[0]->title, 'Scenario: some scenario', 'scenario 1 title');
	my $steps = $scenarios->[0]->steps;
	is($steps->[0]->type, 'GIVEN', 'sc1 st1 type');
	is($steps->[0]->title, 'SC1 ST1', 'sc1 st1 title');
	
	is($steps->[1]->type, 'WHEN', 'sc1 st2 type');
	is($steps->[1]->title, 'SC1 ST2', 'sc2 st1 title');
	
	is($steps->[2]->type, 'THEN', 'sc1 st3 type');
	is($steps->[2]->title, 'SC1 ST3', 'sc1 st3 title');

	is($scenarios->[1]->title, 'Scenario: another scenario', 'sc2 title');
	
	is($scenarios->[2]->title, 'Scenario outline: also scenario-like object', 'sc3 title');
	
	$steps = $scenarios->[2]->steps;
	is($steps->[0]->type, 'GIVEN', 'SO1 ST1 type');
	is($steps->[0]->title, 'SO1 ST1', 'SO1 ST1 title');
	
	is($steps->[1]->type, 'WHEN', 'SO1 ST2 type');
	is($steps->[1]->title, 'SO1 ST2', 'SO1 ST2 title');

	is($steps->[2]->type, 'THEN', 'SO1 ST3 type');
	is($steps->[2]->title, 'SO1 ST3', 'SO1 ST3 title');


	my $examples = $scenarios->[2]->examples;
	is($examples->[0]->title, 'Scenarios: examples', 'examples title' );

	my $table = $examples->[0]->table;
	is_deeply($table->headings, [qw{a b c}], 'table headings');
	is_deeply($table->rows, [
		[0,0,0],
		[0,1,0],
		[1,0,0],
		[1,1,1],
	], 'table rows');

	is($feature->background, instance('background'), 'background ok');
	my $background = $feature->background;
	is($background->title, 'Background: provides context', 'background title ok');
	
	$steps = $background->steps;
	is($steps->[0]->type, 'GIVEN', 'step type ok');
	is($steps->[0]->title, 'context precondition 1', 'step title ok');
	is($steps->[0]->text, "line1\nline2", 'step text ok');
	
	$table = $steps->[0]->table;
	is_deeply($table->headings, [qw{a b c}], "table headings");
	is_deeply($table->rows,[
		[0,0,0],
		[0,1,1],
		[1,0,1],
		[1,1,1],
	], 'table rows');
	
	is($steps->[1]->type, 'AND', 'step type ok');
	is($steps->[1]->title, 'context precondition 2', 'step title ok');
	is($steps->[1]->text, "line 1\nline 2\nline 3\nline 4", 'step text ok');
}

done_testing();


sub cmock_everything {
	cmock($_) for (qw{feature background scenario outline scenarios table step trow});
}

sub get_tokens {
return [
		['PRAG','language','en'],		# ignore
		['TAG', '@name1'],
		['TAG', '@name2'],
		['FEAT', 'Feature: feature title'],
		['NARR', 'line1'],
		['NARR', 'line2'],
		['BGR', 'Background: provides context'],
		['STEP', 'GIVEN', 'context precondition 1'],
		["TEXT", "line1"],
		["TEXT", "line2"],
		['TROW', 'a', 'b', 'c'],
		['TROW', '0', '0', '0'],
		['TROW', '0', '1', '1'],
		['TROW', '1', '0', '1'],
		['TROW', '1', '1', '1'],
		['STEP', 'AND', 'context precondition 2'],
		["TEXT", "line 1"],
		["TEXT", "line 2"],
		["TEXT", "line 3"],
		["TEXT", "line 4"],
		["SCEN", "Scenario: some scenario"],
		['STEP', 'GIVEN', 'SC1 ST1'],
		['STEP', 'WHEN', 'SC1 ST2'],
		['STEP', 'THEN', 'SC1 ST3'],
		["SCEN", "Scenario: another scenario"],
		["OUTL", 'Scenario outline: also scenario-like object'],
		['STEP', 'GIVEN', 'SO1 ST1'],
		['STEP', 'WHEN', 'SO1 ST2'],
		['STEP', 'THEN', 'SO1 ST3'],
		['SCENS', "Scenarios: examples"],
		['TROW', 'a', 'b', 'c'],
		['TROW', '0', '0', '0'],
		['TROW', '0', '1', '0'],
		['TROW', '1', '0', '0'],
		['TROW', '1', '1', '1'],
	];
}