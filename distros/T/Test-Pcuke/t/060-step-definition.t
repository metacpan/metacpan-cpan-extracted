use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Tests::Mockery; Test::Pcuke::Tests::Mockery->import( qw{omock metrics cmock instance} );
}

use_ok( 'Test::Pcuke::StepDefinition' );



done_testing();


sub test_symbol(&$);

###
### Test wrapper
### 
sub test_symbol (&$) {
	my ($code, $step_id) = @_;
	
	my $runner = $Test::Pcuke::StepDefinition::_runner = omock('step_runner');
	
	$code->($step_id);
	
	#my $invocation = inspect($runner)->add_definition(anything);
	#my %args = $invocation ? $invocation->arguments : undef;

	#ok( defined $invocation, q{"Given qr{...} => sub { ... };" works});
	#is( $args{step_type}, uc $step_id, qq{\tstep_type is "Given"});
	#ok( $step_id . ' pattern' =~ $args{regexp}, qq{\tregexp is correct} );
	#is( $args{code}->(), $step_id . ' step_definition', qq{\tcorrect procedure passed});
} 


__END__
test_symbol {
	my $step_id = shift;
	Given qr{^$step_id pattern$} => sub {
		return "$step_id step_definition";
	};
} 'given';

test_symbol {
	my $step_id = shift;
	When qr{^$step_id pattern$} => sub {
		return "$step_id step_definition";
	};
} 'when';

test_symbol {
	my $step_id = shift;
	Then qr{^$step_id pattern$} => sub {
		return "$step_id step_definition";
	};
} 'then';

test_symbol {
	my $step_id = shift;
	And qr{^$step_id pattern$} => sub {
		return "$step_id step_definition";
	};
} 'and';

test_symbol {
	my $step_id = shift;
	But qr{^$step_id pattern$} => sub {
		return "$step_id step_definition";
	};
} 'but';


### expect function
my $expectation_result;
my $expectation_mock = mock;
$Test::Pcuke::StepDefinition::_expectation = $expectation_mock;

when($expectation_mock)->create(anything)
	->then_return($expectation_mock)
	->then_return($expectation_mock);
when($expectation_mock)->equals(anything)
	->then_return(1)
	->then_return(1);

lives_ok {
	$expectation_result = expect();
} 'expect() is exported';

lives_ok {
	$expectation_result = expect(5)->equals(5);
} 'expectations are fullfilled';

done_testing(22);
