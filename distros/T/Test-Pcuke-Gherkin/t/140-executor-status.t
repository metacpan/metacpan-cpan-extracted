use Test::Most;

BEGIN {
	use_ok('Test::Pcuke::Gherkin::Executor::Status');
}

my $CLASS = 'Test::Pcuke::Gherkin::Executor::Status';

new_ok( $CLASS => [], 'status instance' );

{
	my $status = $CLASS->new;
	is($status->status, 'undef', 'status is always "undef"');
}

done_testing();