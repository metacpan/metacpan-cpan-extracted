use Test::Most;
use Scalar::Util qw(refaddr);
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );
	
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Table::Row');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Table::Row';

new_ok( $CLASS => [], 'table row instance');

can_ok($CLASS, qw{set_data data execute status column_status nsteps nscenarios});

{
	my $row = $CLASS->new(); # diag refaddr $row;
	my $data = { a=>'AAA', b=>'BBB' };
	
	$row->set_data( $data );
	
	is_deeply($row->data, $data, "the row keeps data");
}

{
	my $row = $CLASS->new();
	my $data = { a=>'AAA', b=>'BBB' };
	$row->set_data( $data );
	
	my $args;
	
	my $step1 = omock('step', {
		title		=> 'the input "<a>"',
		param_names	=> ['a'],
		type		=> 'WHEN',
		text		=> 'text 1',
		table		=> 'table 1',
		set_params	=> sub { push @{ $args->{set_params} }, [@_] } ,
		execute		=> sub { push @{ $args->{execute} }, 'step1'}, 
		status		=> 'undef',
		exception	=> 'undefined',
	});
	
	my $step2 = omock('step', {
		title		=> 'the output is "<b>"',
		param_names	=> ['b'],
		type		=> 'THEN',
		text 		=> 'text 2',
		table		=> 'table 2',
		set_params	=> sub { push @{ $args->{set_params} }, [@_] } ,
		execute		=> sub { push @{ $args->{execute} }, 'step2'},
		status		=> 'fail',
		exception	=> 'failure',
	});
	
	my $bgr = omock('background', {
		nsteps => {pass=>3, fail=>0, undef=>1 },
		execute		=> sub { push @{ $args->{execute} }, 'bgr'},
	});
	
	$row->execute([ $step1, $step2 ], $bgr);
	
	is_deeply($args->{execute}, [qw{bgr step1 step2}], "execute executes background and then each step");
	is(metrics($step1,'set_params'),	1, "execution sets parameters");
	is_deeply($args->{set_params}->[0]->[1], $data, "step parameters are row data");
	is(metrics($step1, 'unset_params'),	1,	"execution unsets parameters");
	
	is(metrics($step2,'set_params'),	1, "execution sets parameters");
	is_deeply($args->{set_params}->[1]->[1], $data, "step parameters are row data");
	is(metrics($step2, 'unset_params'),	1,	"execution unsets parameters");
	
	is($row->column_status('a'), 'undef', "correct status for column 'a'");
	is($row->column_status('b'), 'fail',  "correct status for column 'b'");
	
	is_deeply( $row->status, { a=>'undef', b=>'fail'}, "correct status for row" );
	
	is_deeply($row->nsteps, {pass=>3, fail=>1, undef=>2}, "correct number of steps");
	is_deeply($row->nscenarios, {pass=>0, fail=>1, undef=>0 }, "correct number of scenarios");
}

done_testing();
