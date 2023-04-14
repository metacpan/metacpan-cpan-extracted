use warnings;
use strict;

use Test::More tests => 1 + 12*8*9 + 21 + 5;

sub slot_value_eq($$) {
	my($x, $y) = @_;
	return !defined($x) && !defined($y) ||
		(ref(\$x) eq "REF" && ref(\$y) eq "REF" && $x == $y);
}

sub slot_list_eq($$) {
	my($x, $y) = @_;
	return @$x == @$y &&
		!(grep { !slot_value_eq($x->[$_], $y->[$_]) } 0..$#$x);
}

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

my $tt0 = variable_tuple();
my $tt1 = variable_tuple();

foreach my $slot_list (
	[],
	[undef],
	[\3],
	[(\my $t0), (\my @t1), (\my %t2), \4],
	[\$::t3, \@::t3, \%::t3, bless({})],
	[sub { my $z = 3 }, \*STDOUT],
	[],
	[],
	[constant_tuple(\2, \3), undef, []],
) {
	foreach my $setup (
		sub { (0, &pure_tuple(@_)) },
		sub { (0, pure_tuple(@_)) },
		sub { (0, &constant_tuple(@_)) },
		sub { (0, constant_tuple(@_)) },
		sub { (1, &variable_tuple(@_)) },
		sub { (1, variable_tuple(@_)) },
		sub { &tuple_set_slots($tt0, @_); (1, $tt0) },
		sub { tuple_set_slots($tt1, @_); (1, $tt1) },
	) {
		my($expect_mutable, $t) = $setup->(@$slot_list);
		is &tuple_mutable($t), !!$expect_mutable;
		is tuple_mutable($t), !!$expect_mutable;
		is &tuple_length($t), scalar(@$slot_list);
		is tuple_length($t), scalar(@$slot_list);
		eval { &tuple_slot($t, -1) };
		like $@, qr/\Atuple slot index is out of range/;
		eval { tuple_slot($t, -1) };
		like $@, qr/\Atuple slot index is out of range/;
		eval { &tuple_slot($t, scalar(@$slot_list)) };
		like $@, qr/\Atuple slot index is out of range/;
		eval { tuple_slot($t, scalar(@$slot_list)) };
		like $@, qr/\Atuple slot index is out of range/;
		ok slot_list_eq([ map { &tuple_slot($t, $_) } 0..$#$slot_list ],
			$slot_list);
		ok slot_list_eq([ map { tuple_slot($t, $_) } 0..$#$slot_list ],
			$slot_list);
		ok slot_list_eq([&tuple_slots($t)], $slot_list);
		ok slot_list_eq([tuple_slots($t)], $slot_list);
	}
}

tuple_set_slots($tt0, \$::t4, \@::t4, undef, \%::t3);
ok slot_list_eq([tuple_slots($tt0)], [\$::t4, \@::t4, undef, \%::t3]);
eval { &tuple_set_slot($tt0, -1, \$::t3) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($tt0, -1, \$::t3) };
like $@, qr/\Atuple slot index is out of range/;
eval { &tuple_set_slot($tt0, 4, \$::t3) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($tt0, 4, \$::t3) };
like $@, qr/\Atuple slot index is out of range/;
ok slot_list_eq([tuple_slots($tt0)], [\$::t4, \@::t4, undef, \%::t3]);
&tuple_set_slot($tt0, 0, \%::t3);
ok slot_list_eq([tuple_slots($tt0)], [\%::t3, \@::t4, undef, \%::t3]);
tuple_set_slot($tt0, 1, undef);
ok slot_list_eq([tuple_slots($tt0)], [\%::t3, undef, undef, \%::t3]);
&tuple_set_slot($tt0, 2, \@::t3);
ok slot_list_eq([tuple_slots($tt0)], [\%::t3, undef, \@::t3, \%::t3]);
tuple_set_slot($tt0, 3, \$::t4);
ok slot_list_eq([tuple_slots($tt0)], [\%::t3, undef, \@::t3, \$::t4]);
is &tuple_mutable($tt0), !!1;
is tuple_mutable($tt0), !!1;
is &tuple_seal($tt0), $tt0;
is &tuple_mutable($tt0), !!0;
is tuple_mutable($tt0), !!0;
eval { &tuple_set_slot($tt0, 1, \$::t3) };
like $@, qr/\AModification of a read-only value attempted/;
eval { tuple_set_slot($tt0, 1, \$::t3) };
like $@, qr/\AModification of a read-only value attempted/;
eval { &tuple_set_slots($tt0, \$::t3) };
like $@, qr/\AModification of a read-only value attempted/;
eval { tuple_set_slots($tt0, \$::t3) };
like $@, qr/\AModification of a read-only value attempted/;
eval { &tuple_seal($tt0) };
like $@, qr/\AModification of a read-only value attempted/;
eval { tuple_seal($tt0) };
like $@, qr/\AModification of a read-only value attempted/;

tuple_set_slots($tt1, \$::t4, \@::t4, undef, \%::t3);
is tuple_mutable($tt1), !!1;
is tuple_seal($tt1), $tt1;
is tuple_mutable($tt1), !!0;
eval { tuple_set_slot($tt1, 1, \$::t3) };
like $@, qr/\AModification of a read-only value attempted/;
eval { tuple_seal($tt1) };
like $@, qr/\AModification of a read-only value attempted/;

1;
