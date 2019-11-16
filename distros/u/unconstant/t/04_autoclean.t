use Test::More tests => 2;

SKIP: {
	eval { require namespace::autoclean };
	skip "namespace::autoclean not installed", 2 if $@;

	package Foo {
		use unconstant;
		use constant FOO => 42;
	}

	package Bar {
		namespace::autoclean->import();
		use unconstant;
		use constant FOO => 42;
	}

	is ( Foo::FOO, 42, "Without namespace::autoclean" );
	is ( Bar::FOO, 42, "With namespace::autoclean" );
}
