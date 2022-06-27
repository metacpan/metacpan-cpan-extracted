use Test::Instruction qw/all/;

{
	package Foo;

	sub new {
		bless {}, shift;
	}

	sub false { 0 }

	sub true { 1 }

	1;
}

instruction(
	test => 'obj',
	instance => 'Foo',
	meth => 'new',
	expected => 'Foo'
);

my $obj = Foo->new();

instruction(
	test => 'hash',
	instance => $obj,
	expected => {}
);

instruction(
	test => 'true',
	instance => $obj,
	meth => 'true',
);

instruction(
	test => 'false',
	instance => $obj,
	meth => 'false',
);

finish();
