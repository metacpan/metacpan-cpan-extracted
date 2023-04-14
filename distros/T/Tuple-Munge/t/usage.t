use warnings;
use strict;

use Test::More tests => 17;

BEGIN {
	use_ok "Tuple::Munge", qw(
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

eval { &tuple_mutable() };
like $@, qr/\AUsage: Tuple::Munge::tuple_mutable\(tuple\)/;
eval { &tuple_mutable(0, 1) };
like $@, qr/\AUsage: Tuple::Munge::tuple_mutable\(tuple\)/;
eval { &tuple_length() };
like $@, qr/\AUsage: Tuple::Munge::tuple_length\(tuple\)/;
eval { &tuple_length(0, 1) };
like $@, qr/\AUsage: Tuple::Munge::tuple_length\(tuple\)/;
eval { &tuple_slot() };
like $@, qr/\AUsage: Tuple::Munge::tuple_slot\(tuple, index\)/;
eval { &tuple_slot(0) };
like $@, qr/\AUsage: Tuple::Munge::tuple_slot\(tuple, index\)/;
eval { &tuple_slot(0, 1, 2) };
like $@, qr/\AUsage: Tuple::Munge::tuple_slot\(tuple, index\)/;
eval { &tuple_slots() };
like $@, qr/\AUsage: Tuple::Munge::tuple_slots\(tuple\)/;
eval { &tuple_slots(0, 1) };
like $@, qr/\AUsage: Tuple::Munge::tuple_slots\(tuple\)/;
eval { &tuple_set_slot() };
like $@, qr/\AUsage: Tuple::Munge::tuple_set_slot\(tuple, index, ref\)/;
eval { &tuple_set_slot(0) };
like $@, qr/\AUsage: Tuple::Munge::tuple_set_slot\(tuple, index, ref\)/;
eval { &tuple_set_slot(0, 1) };
like $@, qr/\AUsage: Tuple::Munge::tuple_set_slot\(tuple, index, ref\)/;
eval { &tuple_set_slot(0, 1, 2, 3) };
like $@, qr/\AUsage: Tuple::Munge::tuple_set_slot\(tuple, index, ref\)/;
eval { &tuple_set_slots() };
like $@, qr/\AUsage: Tuple::Munge::tuple_set_slots\(tuple, ref \.\.\.\)/;
eval { &tuple_seal() };
like $@, qr/\AUsage: Tuple::Munge::tuple_seal\(tuple\)/;
eval { &tuple_seal(0, 1) };
like $@, qr/\AUsage: Tuple::Munge::tuple_seal\(tuple\)/;

1;
