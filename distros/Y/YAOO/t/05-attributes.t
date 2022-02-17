use Test::More;

{
	package Test;

	use YAOO;

	auto_build;

	has [qw/one two three/] => isa(integer);

	has {
		four => { isa(string) },
		five => { isa(hash) }
	}
}

ok(my $test = Test->new(
	one => 1,
	two => 2,
	three => 3,
	four => 'fourth',
	five => { a => "b" },
));

is($test->{one}, 1);
is($test->{four}, 'fourth');

done_testing();
