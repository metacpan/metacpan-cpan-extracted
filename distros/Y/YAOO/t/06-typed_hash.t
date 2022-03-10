use Test::More;

{
	package Test;

	use YAOO;
	use Types::Standard qw/Int Str/;

	auto_build;
	
	has typed => isa(
		typed_hash(
			[
				strict => 1, 
				required => [qw/a b c/], 
				keys => [
					a => Int, 
					b => Str, 
					c => sub { typed_hash([keys => [ d => Str ]], %{$_[0]}) }
				], 
			],
			c => { e => 'after', d => 'abc', },
			a => 211, 
			b => 'test'
		)
	);

	1;
}

{
	package Other;

	use YAOO;
	extends 'Test';
}


ok(my $test = Test->new());

is_deeply( $test->typed, { a => 211, b => 'test', c => { d => 'abc', e => 'after' } } ); 

ok(my $test2 = Test->new( typed => { a => 311, b => 'other', c => { d =>  "okay" } } ));

is_deeply( $test->typed, { a => 311, b => 'other', c => { d => "okay" } });

ok(my $test3 = Other->new());

is_deeply( $test3->typed, { a => 211, b => 'test', c => { d => 'abc', e => 'after' } } ); 

ok(my $test4 = Other->new( typed => { a => 311, b => 'other', c => { d =>  "okay" } } ));

is_deeply( $test4->typed, { a => 311, b => 'other', c => { d => "okay" } });

done_testing();

