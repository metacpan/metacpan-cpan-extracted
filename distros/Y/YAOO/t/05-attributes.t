use Test::More;

{
	package Test;

	use YAOO;

	auto_build;

	has [qw/one two three/] => isa(integer), lazy, build_order(1);

	has {
		four => { isa(string) },
		five => { isa(hash) }
	};

	has six => isa(string(1)), delay, coerce(sub { $_[0]->three + $_[0]->two + $_[0]->one });

}

ok(my $test = Test->new(
	one => 1,
	two => 2,
	three => 3,
	four => 'fourth',
	five => { a => "b" },
));

is($test->one, 1);
is($test->four, 'fourth');
is($test->six, 6);
is($test->one(undef), undef);


done_testing();

