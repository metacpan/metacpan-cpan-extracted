use Test::Instruction qw/all/;

{
	package Foo;

	sub append_str {
		$_[0] . ' ' . $_[1];
	}

	sub false { 0 }

	sub true { 1 }

	1;
}

instruction(
	test => 'ok',
	func => \&Foo::true,
);

instruction(
	test => 'true',
	func => \&Foo::true,
);

instruction(
	test => 'false',
	func => \&Foo::false,
);


instruction(
	test => 'scalar',
	func => \&Foo::append_str,
	args => [
		'first', 'second'
	],
	args_list => 1,
	expected  => 'first second',
);

instruction(
	test => 'like',
	func => \&Foo::append_str,
	args => [
		'first', 'second'
	],
	args_list => 1,
	expected  => 'first second',
);

finish();

