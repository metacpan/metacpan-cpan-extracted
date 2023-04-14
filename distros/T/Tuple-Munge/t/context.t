use warnings;
use strict;

use Test::More tests => 1 + 7*6*2 + 12 + 6*3 + 7 + 12*2 + 12*2;

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

sub unwrap_list($) {
	my($a) = @_;
	my @a = @$a;
	@a >= 4 && ref($a[0]) eq "" && $a[0] eq 11 &&
			ref($a[1]) eq "" && $a[1] eq 22 &&
			ref($a[-2]) eq "" && $a[-2] eq 33 &&
			ref($a[-1]) eq "" && $a[-1] eq 44
		or return ["wrap error"];
	shift(@a); shift(@a); pop(@a); pop(@a);
	return \@a;
}

sub unwrap_one($) {
	my $a = unwrap_list($_[0]);
	@$a == 1 or return "wrap error";
	return $a->[0];
}

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

foreach my $slot_list (
        [],
	[\3, []],
) {
	foreach my $construct (
		sub { &pure_tuple(@_) },
		sub { pure_tuple(@_) },
		sub { &constant_tuple(@_) },
		sub { constant_tuple(@_) },
		sub { &variable_tuple(@_) },
		sub { variable_tuple(@_) },
	) {
		my $t = unwrap_one([11, 22, scalar($construct->(@$slot_list)),
					33, 44]);
		is ref(\$t), "REF";
		is ref($t), "OBJECT";
		ok slot_list_eq([tuple_slots($t)], $slot_list);
		$t = unwrap_one([11, 22, $construct->(@$slot_list), 33, 44]);
		is ref(\$t), "REF";
		is ref($t), "OBJECT";
		ok slot_list_eq([tuple_slots($t)], $slot_list);
		is_deeply unwrap_list([11, 22,
				do { $construct->(@$slot_list); () }, 33, 44]),
			[];
	}
}

my $tt0 = constant_tuple(\3, \4, \5);
is unwrap_one([11, 22, scalar(&tuple_mutable($tt0)), 33, 44]), !!0;
is unwrap_one([11, 22, scalar(tuple_mutable($tt0)), 33, 44]), !!0;
is unwrap_one([11, 22, &tuple_mutable($tt0), 33, 44]), !!0;
is unwrap_one([11, 22, tuple_mutable($tt0), 33, 44]), !!0;
is_deeply unwrap_list([11, 22, do { &tuple_mutable($tt0); () }, 33, 44]), [];
is_deeply unwrap_list([11, 22, do { tuple_mutable($tt0); () }, 33, 44]), [];
my $tt1 = variable_tuple(\3, \4, \5);
is unwrap_one([11, 22, scalar(&tuple_mutable($tt1)), 33, 44]), !!1;
is unwrap_one([11, 22, scalar(tuple_mutable($tt1)), 33, 44]), !!1;
is unwrap_one([11, 22, &tuple_mutable($tt1), 33, 44]), !!1;
is unwrap_one([11, 22, tuple_mutable($tt1), 33, 44]), !!1;
is_deeply unwrap_list([11, 22, do { &tuple_mutable($tt1); () }, 33, 44]), [];
is_deeply unwrap_list([11, 22, do { tuple_mutable($tt1); () }, 33, 44]), [];

my $tt2 = variable_tuple(\3, \4, \5);
is unwrap_one([11, 22, scalar(&tuple_length($tt2)), 33, 44]), 3;
is unwrap_one([11, 22, scalar(tuple_length($tt2)), 33, 44]), 3;
is unwrap_one([11, 22, &tuple_length($tt2), 33, 44]), 3;
is unwrap_one([11, 22, tuple_length($tt2), 33, 44]), 3;
is_deeply unwrap_list([11, 22, do { &tuple_length($tt2); () }, 33, 44]), [];
is_deeply unwrap_list([11, 22, do { tuple_length($tt2); () }, 33, 44]), [];

my $tt3 = variable_tuple(\3, \4, \$::s0);
ok slot_value_eq(unwrap_one([11, 22, scalar(&tuple_slot($tt3, 2)), 33, 44]),
	\$::s0);
ok slot_value_eq(unwrap_one([11, 22, scalar(tuple_slot($tt3, 2)), 33, 44]),
	\$::s0);
ok slot_value_eq(unwrap_one([11, 22, &tuple_slot($tt3, 2), 33, 44]), \$::s0);
ok slot_value_eq(unwrap_one([11, 22, tuple_slot($tt3, 2), 33, 44]), \$::s0);
is_deeply unwrap_list([11, 22, do { &tuple_slot($tt3, 2); () }, 33, 44]), [];
is_deeply unwrap_list([11, 22, do { tuple_slot($tt3, 2); () }, 33, 44]), [];

my @sl4 = (\@::s0, \%::s0, \$::s0);
my $tt4 = variable_tuple(@sl4);
eval { my $z = [11, 22, scalar(&tuple_slots($tt4)), 33, 44] };
like $@, qr/\Atuple slot list requested in scalar context/;
eval { my $z = [11, 22, scalar(tuple_slots($tt4)), 33, 44] };
like $@, qr/\Atuple slot list requested in scalar context/;
ok slot_list_eq(unwrap_list([11, 22, &tuple_slots($tt4), 33, 44]), \@sl4);
ok slot_list_eq(unwrap_list([11, 22, tuple_slots($tt4), 33, 44]), \@sl4);
is_deeply unwrap_list([11, 22, do { &tuple_slots($tt4); () }, 33, 44]), [];
is_deeply unwrap_list([11, 22, do { tuple_slots($tt4); () }, 33, 44]), [];

my $tt5 = variable_tuple(\$::s0, \@::s0, \%::s0, \$::s0, \@::s0, \%::s0);
ok slot_value_eq(unwrap_one([11, 22, scalar(&tuple_set_slot($tt5, 0, \%::s1)),
				33, 44]),
	\%::s1);
ok slot_value_eq(unwrap_one([11, 22, scalar(tuple_set_slot($tt5, 1, \$::s2)),
				33, 44]),
	\$::s2);
ok slot_value_eq(unwrap_one([11, 22, &tuple_set_slot($tt5, 2, \@::s2), 33, 44]),
	\@::s2);
ok slot_value_eq(unwrap_one([11, 22, tuple_set_slot($tt5, 3, \%::s2), 33, 44]),
	\%::s2);
is_deeply unwrap_list([11, 22, do { &tuple_set_slot($tt5, 4, \$::s3); () },
				33, 44]),
	[];
is_deeply unwrap_list([11, 22, do { tuple_set_slot($tt5, 5, \@::s3); () },
				33, 44]),
	[];
ok slot_list_eq([tuple_slots($tt5)],
	[\%::s1, \$::s2, \@::s2, \%::s2, \$::s3, \@::s3]);

my $tt6 = variable_tuple(undef, \$::s0, \@::s0, \%::s0);
is unwrap_one([11, 22, scalar(&tuple_set_slots($tt6, \@::s1, \%::s1)), 33, 44]),
	undef;
ok slot_list_eq([tuple_slots($tt6)], [\@::s1, \%::s1]);
is unwrap_one([11, 22, scalar(tuple_set_slots($tt6, \%::s1, \@::s1)), 33, 44]),
	undef;
ok slot_list_eq([tuple_slots($tt6)], [\%::s1, \@::s1]);
is_deeply unwrap_list([11, 22, &tuple_set_slots($tt6, \@::s2, \%::s2), 33, 44]),
	[];
ok slot_list_eq([tuple_slots($tt6)], [\@::s2, \%::s2]);
is_deeply unwrap_list([11, 22, tuple_set_slots($tt6, \%::s2, \@::s2), 33, 44]),
	[];
ok slot_list_eq([tuple_slots($tt6)], [\%::s2, \@::s2]);
is_deeply unwrap_list([11, 22,
		do { &tuple_set_slots($tt6, \@::s3, \%::s3); () }, 33, 44]),
	[];
ok slot_list_eq([tuple_slots($tt6)], [\@::s3, \%::s3]);
is_deeply unwrap_list([11, 22,
		do { tuple_set_slots($tt6, \%::s3, \@::s3); () }, 33, 44]),
	[];
ok slot_list_eq([tuple_slots($tt6)], [\%::s3, \@::s3]);

my $tt7;
$tt7 = variable_tuple(\$::s0);
ok slot_value_eq(unwrap_one([11, 22, scalar(&tuple_seal($tt7)), 33, 44]), $tt7);
ok !tuple_mutable($tt7);
$tt7 = variable_tuple(\$::s0);
ok slot_value_eq(unwrap_one([11, 22, scalar(tuple_seal($tt7)), 33, 44]), $tt7);
ok !tuple_mutable($tt7);
$tt7 = variable_tuple(\$::s0);
ok slot_value_eq(unwrap_one([11, 22, &tuple_seal($tt7), 33, 44]), $tt7);
ok !tuple_mutable($tt7);
$tt7 = variable_tuple(\$::s0);
ok slot_value_eq(unwrap_one([11, 22, tuple_seal($tt7), 33, 44]), $tt7);
ok !tuple_mutable($tt7);
$tt7 = variable_tuple(\$::s0);
is_deeply unwrap_list([11, 22, do { &tuple_seal($tt7); () }, 33, 44]), [];
ok !tuple_mutable($tt7);
$tt7 = variable_tuple(\$::s0);
is_deeply unwrap_list([11, 22, do { tuple_seal($tt7); () }, 33, 44]), [];
ok !tuple_mutable($tt7);

my $tt8 = variable_tuple(\$::s0, \@::s0);
is 0+@{[&tuple_slots($tt8)]}, 2;
is 0+@{[tuple_slots($tt8)]}, 2;
is 0+@{[sub { &tuple_slots($tt8) }->()]}, 2;
is 0+@{[sub { tuple_slots($tt8) }->()]}, 2;
eval { my $z = &tuple_slots($tt8); };
like $@, qr/\Atuple slot list requested in scalar context/;
eval { my $z = tuple_slots($tt8); };
like $@, qr/\Atuple slot list requested in scalar context/;
eval { my $z = sub { &tuple_slots($tt8) }->(); };
like $@, qr/\Atuple slot list requested in scalar context/;
eval { my $z = sub { tuple_slots($tt8) }->(); };
like $@, qr/\Atuple slot list requested in scalar context/;
is do { &tuple_slots($tt8); 0 }, 0;
is do { tuple_slots($tt8); 0 }, 0;
is do { sub { &tuple_slots($tt8) }->(); 0 }, 0;
is do { sub { tuple_slots($tt8) }->(); 0 }, 0;

my $tt9 = variable_tuple(\%::s0);
is 0+@{[&tuple_set_slots($tt9, \%::s0)]}, 0;
is 0+@{[tuple_set_slots($tt9, \%::s0)]}, 0;
is 0+@{[sub { &tuple_set_slots($tt9, \%::s0) }->()]}, 0;
is 0+@{[sub { tuple_set_slots($tt9, \%::s0) }->()]}, 0;
is scalar(&tuple_set_slots($tt9, \%::s0)), undef;
is scalar(tuple_set_slots($tt9, \%::s0)), undef;
is scalar(sub { &tuple_set_slots($tt9, \%::s0) }->()), undef;
is scalar(sub { tuple_set_slots($tt9, \%::s0) }->()), undef;
is do { &tuple_set_slots($tt9, \%::s0); 0 }, 0;
is do { tuple_set_slots($tt9, \%::s0); 0 }, 0;
is do { sub { &tuple_set_slots($tt9, \%::s0) }->(); 0 }, 0;
is do { sub { tuple_set_slots($tt9, \%::s0) }->(); 0 }, 0;

1;
