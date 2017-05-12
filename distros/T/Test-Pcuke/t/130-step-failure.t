use Test::Most;

BEGIN {
	use_ok('Test::Pcuke::Executor::StepFailure');
}

my $CLASS = 'Test::Pcuke::Executor::StepFailure';

new_ok( $CLASS => [], 'exception instance');
can_ok( $CLASS, qw{message} );

{
	my $msg = 'a message';
	my $exception = $CLASS->new($msg); 
	
	is($exception->message, 'a message', 'the object keeps a message that is set with set_message()');	
}

done_testing();
__END__
