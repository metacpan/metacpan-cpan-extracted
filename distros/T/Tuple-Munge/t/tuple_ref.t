use warnings;
use strict;

use Test::More tests => 1 + 26*14;

BEGIN {
	use_ok "Tuple::Munge", qw(
		constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

{
	use feature "class";
	no warnings "experimental::class";
	class Foo;
	field $aa;
}

format foofmt =
.

foreach my $use_sub (
	sub { &tuple_mutable($_[0]) },
	sub { tuple_mutable($_[0]) },
	sub { &tuple_length($_[0]) },
	sub { tuple_length($_[0]) },
	sub { &tuple_slot($_[0], 0) },
	sub { tuple_slot($_[0], 0) },
	sub { [&tuple_slots($_[0])] },
	sub { [tuple_slots($_[0])] },
	sub ($) { &tuple_set_slot($_[0], 0, (\my $p)) },
	sub ($) { tuple_set_slot($_[0], 0, (\my $p)) },
	sub ($) { &tuple_set_slots($_[0], (\my $p)) },
	sub ($) { tuple_set_slots($_[0], (\my $p)) },
	sub ($) { &tuple_seal($_[0]) },
	sub ($) { tuple_seal($_[0]) },
) {
	foreach my $value (
		undef,
		(my $t0),
		"a",
		1,
		*g,
		${qr/foo/},
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
	) {
		eval { $use_sub->($value) };
		like $@, qr/\Atuple argument is not a tuple reference/;
	}
	foreach my $value (
		constant_tuple(\my $t7),
		tuple_seal(bless(variable_tuple(\my $t8))),
		variable_tuple(\my $t9),
		bless(variable_tuple(\my $t10)),
		Foo->new,
	) {
		my $mutable = tuple_mutable($value);
		eval { $use_sub->($value) };
		if((prototype($use_sub) // "") eq "\$" && !$mutable) {
			like $@, qr/\AModification\ of
					\ a\ read-only\ value\ attempted/x;
		} else {
			is $@, "";
		}
	}
}

1;
