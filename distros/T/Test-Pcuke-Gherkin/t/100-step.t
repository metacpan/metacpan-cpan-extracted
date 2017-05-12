use Test::Most;
use Scalar::Util qw{refaddr};
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Step');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Step';

new_ok($CLASS => [], 'step instance');

can_ok($CLASS, qw{
	set_type	set_title	set_table	set_text	set_params
	type		title		table		text		unset_params
	execute		status		param_names
	executor
});

{
	my $step = $CLASS->new();
	
	throws_ok {
		$step->set_type('WRONG');
	} qr{type of the step}, 'Throws if type is not GIVEN|WHEN|THEN|AND';

	$step->set_type('given');

	is($step->type, 'GIVEN', 'set_type() stores the type, type() returns the type of the step');

	throws_ok {
		$step->set_type('when');
	} qr{immutable}, 'type is an immutable property';
}


lives_ok {
	my $s1 = $CLASS->new({ type => 'tHeN' });
	my $s2 = $CLASS->new({ type => 'GIVEN'});
	my $s3 = $CLASS->new({ type => 'and'  });
	my $s4 = $CLASS->new({ type => 'but'  });
	my $s5 = $CLASS->new({ type => '*'    });
} 'valid types are GIVEN, WHEN, THEN, AND, BUT and * and are case-insensitive, but normalized to upper case';

{
	my $executor = omock('executor');
	my $table = omock('table');
	
	my $conf = {
		type	=> 'given',
		title	=> 'title',	
		text	=> 'text',
		table	=> $table,
		executor=> $executor,
	};
	
	my $step = $CLASS->new( $conf );
	
	is($step->type,		$conf->{type},		'type may be set in constructor');
	is($step->title,	$conf->{title},		'title may be set in constructor');
	is($step->text,		$conf->{text},		'text may be set in constructor');
	is($step->table,	$conf->{table},		'table may be set in constructor');
	is($step->executor,	$conf->{executor},	'executor may be set in constructor');
}
{
	my $step = $CLASS->new({ type => 'GIVEN' });

	is( $step->title, q{}, 'Step has an empty title if that is not specified');

	$step->set_title();

	throws_ok {
		$step->set_title('another title');
	} qr{immutable}, 'title is immutable';


	$step->set_table();
	is( $step->table, q{}, 'empty hash is returned when no arguments passed to set_table');

	throws_ok {
		$step->set_table();
	} qr{immutable}, 'table is an immutable property';
}

{
	my $table_mock = 'must be T::C::Table';
	my $step = $CLASS->new({ type => 'GIVEN' });
	
	$step->set_table( $table_mock );
	is( $step->table, $table_mock, 'step keeps the table object' );
}

{
	my $args;
	my $status = omock('execution_status', {
		status	=> 'pass'
	});
	
	my $executor = omock('executor', {
		execute => sub {
			push @{ $args->{execute} }, [@_];
			return $status;
		}
	});

	my $step = $CLASS->new({
		type		=> 'GIVEN',
		title		=> 'test step',
		executor	=> $executor,
	});
	
	$step->execute;

	is($args->{execute}->[0]->[1], $step, 'step is passed to executor');
	is($step->status, 'pass', 'step status ok');
}

{
	my %status = (
		'undef'	=> [undef, 'undef', 'undefined'],
		'pass'	=> [1, 'true string', 'pass', 'passed'],
		'fail'	=> [0, '', 'fail', 'failure'],
	);
	
	for my $status ( keys %status ){
		for my $return ( @{ $status{$status} } ){
			my $executor = omock('executor', {
				# execute => $return does not work
				# if $return is undefined
				execute => sub { return $return },
			});

			my $step = $CLASS->new({
				type		=> 'GIVEN',
				title		=> 'test step',
				executor	=> $executor,
			});
	
			$step->execute;

			my $txt = defined $return ? $return : '{undef}';
			is($step->status, $status, "'$txt' means the status '$status'");
		}
	}
}


{
	my $step = $CLASS->new({
		type => 'GIVEN',
		title => 'test step',
	});

	lives_ok {
		$step->set_text('some text');
	} 'step may be queried to add text';

	lives_ok {
		$step->text;
	} 'step can be queried for text';

	is ($step->text, 'some text', 'step keeps the text');
}

{
	my $step = $CLASS->new({
		type => 'GIVEN',
		title => 'test step',
	});

	ok(!defined $step->text, 'if not set, text is undefined!');
}

{
	my $step = $CLASS->new({
		type => 'GIVEN',
		title => 'parametrised step test <n>',
	});
	
	$step->set_params({ n => 'MMM'});
	
	is($step->title, 'parametrised step test "MMM"', "parameters are replaced when set");
	
	$step->unset_params;
	
	is($step->title, 'parametrised step test <n>', "original title is restored when unset_params");
}

{
	my $step = $CLASS->new({
		type => 'GIVEN',
		title => 'parametrised step <m> test <nnn>',
	});
	
	is_deeply([ sort @{ $step->param_names } ], ['m', 'nnn'], "param_names() returns a ref to an array of parameter names that affect the step");
	
	$step->set_params({ m=>'MMM', n=>'NNN' });
	
	is_deeply([ sort @{ $step->param_names } ], ['m', 'nnn'], "param_names() is not affected by set_params()/unset_params");
	
}

done_testing();
