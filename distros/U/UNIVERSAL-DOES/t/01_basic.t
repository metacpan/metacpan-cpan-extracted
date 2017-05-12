#!perl -w
use strict;
use Test::More tests => 44;

use UNIVERSAL::DOES qw(does);

BEGIN{
	no strict 'vars';

	package FooBase;

	sub new{
		bless {ok => 1}, shift;
	}

	package Callable;
	use overload '&{}' => 'as_code', fallback => 1;

	sub as_code{
		my($self) = @_;
		return sub{ $self->call(@_) };
	}

	sub call{
		die "call() is ABSTRACT";
	}

	package Foo;
	@ISA = qw(FooBase Callable);

	sub call{
		return 'foo!';
	}

	package BarBase;

	sub new{
		bless {}, shift;
	}

	package Bar;
	@ISA = qw(BarBase);

	sub DOES{
		my($self, $role) = @_;
		return $self->SUPER::DOES($role) || Foo->DOES($role); # mock
	}
}

my $foo = Foo->new;

ok does('Foo', 'Foo'), 'for classes';
ok!does('Foo', 'Bar');
ok does('Foo', 'FooBase');
ok does('Foo', 'UNIVERSAL');
ok!does('Foo', undef);

ok does($foo, 'Foo'), 'for object instances';
ok does($foo, 'FooBase');
ok does($foo, 'Callable');
ok does($foo, 'UNIVERSAL');

ok does($foo, 'HASH'), 'foo does a HASH ref';
ok does($foo, 'CODE'), 'foo does also a CODE ref';
ok!does($foo, 'ARRAY'), 'foo does not an ARRAY ref';

ok $foo->{ok},       'treat foo as a HASH ref';
is $foo->(), 'foo!', 'treat foo as a CODE ref';

ok !does($foo, 'Bar');
ok !does($foo, 'SCALAR');
ok !does($foo, 'ARRAY');
ok !does($foo, 'GLOB');

my $bar = Bar->new;

ok does('Bar', 'Bar');
ok does('Bar', 'BarBase');
ok does('Bar', 'Foo');
ok does('Bar', 'FooBase');
ok does('Bar', 'UNIVERSAL');

ok does($bar, 'Bar');
ok does($bar, 'BarBase');
ok does($bar, 'Foo'), 'fake Foo';
ok does($bar, 'FooBase');
ok does($bar, 'Callable');
ok does($bar, 'UNIVERSAL');

ok  does($bar, 'HASH');
ok !does($bar, 'CODE');

# for non-object

ok !does(undef, 'UNIVERSAL');

SKIP: {
    skip "changed on 5.18", 2 if $] > 5.016;
    ok !does(42,    'UNIVERSAL');
    ok !does('!',   'UNIVERSAL');
}

ok  does([], 'ARRAY');
ok !does([], 'HASH');
ok !does([], 'UNIVERSAL');

ok  does({}, 'HASH');
ok !does({}, 'ARRAY');
ok !does({}, 'UNIVERSAL');

ok  does(qr/foo/, 'Regexp');
ok  does(qr/foo/, 'UNIVERSAL');

eval{
	$foo->DOES();
};
like $@, qr/Usage: /;

eval{
	$foo->DOES(1, 2);
};
like $@, qr/Usage: /;
