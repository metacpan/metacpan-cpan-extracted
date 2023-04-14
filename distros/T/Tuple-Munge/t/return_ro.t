use warnings;
use strict;

use Test::More tests => 11;

sub ok_immutable($) {
	eval { $_[0] = 0 };
	like $@, qr/\AModification of a read-only value attempted/;
}

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

ok_immutable pure_tuple(\$::s0);
ok_immutable constant_tuple(\$::s0);
ok_immutable variable_tuple(\$::s0);
my $tt0 = variable_tuple(\$::s0);
ok_immutable tuple_mutable($tt0);
ok_immutable tuple_length($tt0);
ok_immutable tuple_slot($tt0, 0);
&ok_immutable(tuple_slots($tt0));
ok_immutable tuple_set_slot($tt0, 0, \@::s0);
ok_immutable tuple_set_slots($tt0, \%::s0);
ok_immutable tuple_seal($tt0);

1;
