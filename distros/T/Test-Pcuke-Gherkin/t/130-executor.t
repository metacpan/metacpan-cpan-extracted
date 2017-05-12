use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );

	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Executor');
}

my $CLASS = 'Test::Pcuke::Gherkin::Executor';

new_ok($CLASS=>[], 'executor instance');

diag '###	Executor warns that it does nothing with the step - this is intended behaviour';

{
	cmock('execution_status');
	my $step = omock('step');
	
	my $executor = $CLASS->new;
	my $result = $executor->execute($step);
	
	is($result, instance('execution_status'), 'returns execution status');
}

done_testing();
