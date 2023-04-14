use warnings;
use strict;

use Test::More tests => 1 + 26*10;

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

my $tt = variable_tuple(undef);

{
	use feature "class";
	no warnings "experimental::class";
	class Foo;
	field $aa;
}

format foofmt =
.

foreach my $use_sub (
	sub { &pure_tuple($_[0]) },
	sub { pure_tuple($_[0]) },
	sub { &constant_tuple($_[0]) },
	sub { constant_tuple($_[0]) },
	sub { &variable_tuple($_[0]) },
	sub { variable_tuple($_[0]) },
	sub { &tuple_set_slot($tt, 0, $_[0]) },
	sub { tuple_set_slot($tt, 0, $_[0]) },
	sub { &tuple_set_slots($tt, $_[0]) },
	sub { tuple_set_slots($tt, $_[0]) },
) {
	foreach my $value (
		"a",
		1,
		*g,
		${qr/foo/},
	) {
		eval { $use_sub->($value) };
		like $@, qr/\Aslot value is neither a reference nor undefined/;
	}
	foreach my $value (
		undef,
		(my $t0),
		\undef,
		(\my $t1),
		\"b",
		\1,
		\*g,
		qr/foo/,
		bless(\my $t2),
		(\my @t3),
		bless(\my @t4),
		(\my %t5),
		bless(\my %t6),
		sub { my $z = $use_sub },
		bless(sub { my $z = $use_sub }),
		*foofmt{FORMAT},
		\*STDOUT,
		constant_tuple(\my $t7),
		tuple_seal(bless(variable_tuple(\my $t8))),
		variable_tuple(\my $t9),
		bless(variable_tuple(\my $t10)),
		Foo->new,
	) {
		eval { $use_sub->($value) };
		is $@, "";
	}
}

1;
