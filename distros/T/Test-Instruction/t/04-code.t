use Test::Instruction qw/all/;

{
	package Foo;

	sub new {
		bless {}, shift;
	}

	sub block { return sub { 1 + 1 } }

	sub block_ref { return sub { { a => 1, b => 2, c => 3 } } }
	
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
	test => 'code',
	instance => $obj,
	meth => 'block',
);

instruction(
	test => 'code_execute',
	instance => $obj,
	meth => 'block',
	expected => 2
);

instruction(
	test => 'code',
	instance => $obj,
	meth => 'block_ref',
);

instruction(
	test => 'code_execute',
	instance => $obj,
	meth => 'block_ref',
	expected => { a => 1, b => 2, c => 3 }
);

finish();
