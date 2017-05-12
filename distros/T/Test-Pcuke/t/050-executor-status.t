use Test::Most;

BEGIN {
	use_ok('Test::Pcuke::Executor::Status');
}

my $CLASS = 'Test::Pcuke::Executor::Status';

new_ok( $CLASS => [], 'status instance' );

can_ok( $CLASS, qw{status exception} );
{
	my $status = $CLASS->new();
	
	is($status->status, 'undef', 'by default status is "undef"');
	ok( !defined $status->exception, 'by default exception is undefined')
}

{
	my $status = $CLASS->new('fail', 'exception');
	
	is($status->status, 'fail', 'instance keeps the status');
	is($status->exception, 'exception', 'instance keeps the exception');
}
done_testing();