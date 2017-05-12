use Test::Most;

BEGIN {
	use_ok('Test::Pcuke::Gherkin::Lexer');
}

my $class = 'Test::Pcuke::Gherkin::Lexer';

my $tests	= [
	{
		levels	=> ['steps'],
		ttl		=> 'complete step description: step + text + table',
		inp		=> << 'END',
	* some step
	"""
	it has a text
	which can be multiline
	"""
	| a | b | result |
	| 0 | 0 |      0 |
	| 0 | 1 |      1 |
	| 1 | 0 |      1 |
	| 1 | 1 |      0 |
	
END
		out	=> [
			['STEP', '*', 'some step'],
			['TEXT', 'it has a text'],
			['TEXT', 'which can be multiline'],
			['TROW', 'a', 'b', 'result'],
			['TROW', 0, 0, 0],
			['TROW', 0, 1, 1],
			['TROW', 1, 0, 1],
			['TROW', 1, 1, 0],
		],
	},
	
	{
		levels	=> ['steps'],
		ttl	=> 'text is recognized in steps',
		inp	=> << 'END',
	"""
	this is
	a very
	very
	very multiline text
	"""
END
		out	=> [
			['TEXT', 'this is'],
			['TEXT', 'a very'],
			['TEXT', 'very'],
			['TEXT', 'very multiline text'],
		],
	},
	
	{
		levels	=> ['scenarios'],
		ttl	=> 'tables in scenarios are recognized',
		inp	=> << 'END',
	| a | b | result |
	| 0 | 0 |      0 |
	| 0 | 1 |      1 |
	| 1 | 0 |      1 |
	| 1 | 1 |      0 |
END
		out => [
			['TROW', 'a', 'b', 'result'],
			['TROW', 0, 0, 0],
			['TROW', 0, 1, 1],
			['TROW', 1, 0, 1],
			['TROW', 1, 1, 0],
		],
	},
	{
		levels	=> ['outline'],
		ttl		=> 'scenarios and examples are recognized',
		inp		=> << 'END',
	Scenarios: scenarios title
	
	Examples: examples title
	
END
		out	=> [
			['SCENS', 'Scenarios: scenarios title'],
			['SCENS', 'Examples: examples title'],
		],
	},
	{
		levels	=> [qw{steps}],
		ttl	=> 'all steps are recognized',
		inp	=> << 'END',
	Given given step
	When when step
	Then then step
	And and step
	But but step
	* asterisk step
END
		out	=> [
			['STEP','GIVEN','given step'],
			['STEP',"WHEN",	'when step'],
			['STEP',"THEN",	'then step'],
			['STEP',"AND",	'and step'],
			['STEP',"BUT",	'but step'],
			['STEP',"*",	'asterisk step'],
		],
	},
	{
		ttl	=> 'non-recognized lines are probably Narrative on the feature level',
		inp	=> <<'END',
Feature: feature

	narrative line 1
	narrative line 2
	
	Background: bgr
		Given precondition 1
		And precondition 2
	
	Scenario: scenario1
END
		out	=> [
			['FEAT', 'Feature: feature'],
			['NARR', 'narrative line 1'],
			['NARR', 'narrative line 2'],
			['BGR', 'Background: bgr'],
			["STEP", "GIVEN", 'precondition 1'],
			["STEP", "AND", 'precondition 2'],
			['SCEN', 'Scenario: scenario1']
		],
	},
	
	{
		ttl	=> 'scenario outline is recognized',
		inp	=> << 'END',
Feature: a feature
	Scenario Outline: title of the outline
END
		out	=> [
			['FEAT', 'Feature: a feature'],
			['OUTL', 'Scenario Outline: title of the outline']
		],
	},
	
	{
		ttl	=> 'scenario is recognized',
		inp	=> << 'END',
Feature: feature title
	Scenario: some scenario
END
		out	=> [
			['FEAT', 'Feature: feature title'],
			['SCEN', 'Scenario: some scenario']
		],
	},
	
	{
		ttl	=> 'background lexem is recognized',
		inp => << 'END',
Feature: feature title
	Background: some background	
END
		out => [
			['FEAT', 'Feature: feature title'],
			['BGR', 'Background: some background'],
		],
	},
	{
		ttl	=> 'empty lines and comments and "pragmas" are skipped on a feature level',
		inp	=> << 'END',
# language: ru

@feature_tag

Feature: feature title

	# comment is skipped
	# name: value pragmas are comments and skipped

	@scenarioid_tag
	# comments are skipped
END
		out	=> [
			['PRAG', 'language', 'ru'],
			['TAG','@feature_tag'],
			['FEAT','Feature: feature title'],
			['TAG', '@scenarioid_tag']
		],
	},
	{
		ttl	=> "comments are skipped",
		inp	=> "# a comment",
		out	=> []
	},
	
	{
		ttl	=> "pragmas are lexems ['PRAG', \$name, \$value]",
		inp	=> "# language: ru",
		out	=> [['PRAG','language', 'ru']],
	},
	
	{
		ttl	=> "two pragmas on two lines",
		inp	=> "#language: ru\n#something: else",
		out	=> [['PRAG', 'language', 'ru'], ['PRAG', 'something', 'else']],
	},
	
	{
		ttl	=> 'tags are lexems: ["TAG", <tag name>]',
		inp	=> '@tag_name',
		out	=> [['TAG', '@tag_name']],
		
	},
	
	{
		ttl	=> 'many tags on tany lines',
		inp	=> << 'END',
@tag_11 @tag_12 @tag_13
@tag_21
@tag_31 @tag_32
END
		out	=> [
			['TAG', '@tag_11'],
			['TAG', '@tag_12'],
			['TAG', '@tag_13'],
			['TAG', '@tag_21'],
			['TAG', '@tag_31'],
			['TAG', '@tag_32'],
		],
	},
	
	{
		ttl	=> 'feature is a lexem: ["FEAT", <title>]',
		inp	=> 'Feature: a feature',
		out	=> [['FEAT', 'Feature: a feature']],
	},
	
	{
		ttl	=> 'wrong line is a lexem: ["ERR", <line>]',
		inp => 'wrong syntax unrecognized by scanner',
		out	=> [['ERR', 'wrong syntax unrecognized by scanner']],
	},
];


foreach ( @$tests ) {
	$class->reset;
	$class->_append_levels( @{ $_->{levels} } )
		if $_->{levels};
	my $result = $class->scan( $_->{inp} );
	# is_deeply($result, $_->{out}, $_->{ttl} );
}

done_testing();