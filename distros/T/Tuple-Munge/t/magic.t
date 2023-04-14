use warnings;
use strict;

use Test::More tests => 59;

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

my $magic;
my $fetched;
{
	package t::TiedScalar::CountFetch;
	sub TIESCALAR { bless({ value => $_[1] }, $_[0]) }
	sub FETCH { $fetched++; $_[0]->{value} }
}
sub tm1(&$;$) {
	untie $magic;
	$magic = $_[2];
	tie $magic, "t::TiedScalar::CountFetch", $_[1];
	$fetched = 0;
	$_[0]->();
	is $fetched, 1;
}

tm1 {
	ok tuple_slot(pure_tuple($magic), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(pure_tuple($magic, \5), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(pure_tuple(\5, $magic), 1) == \$::s0;
} \$::s0, \$::s1;

tm1 {
	ok tuple_slot(constant_tuple($magic), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(constant_tuple($magic, \5), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(constant_tuple(\5, $magic), 1) == \$::s0;
} \$::s0, \$::s1;

tm1 {
	ok tuple_slot(variable_tuple($magic), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(variable_tuple($magic, \5), 0) == \$::s0;
} \$::s0, \$::s1;
tm1 {
	ok tuple_slot(variable_tuple(\5, $magic), 1) == \$::s0;
} \$::s0, \$::s1;

tm1 {
	is tuple_mutable($magic), !!1;
} variable_tuple(), constant_tuple();
tm1 {
	is tuple_mutable($magic), !!0;
} constant_tuple(), variable_tuple();

tm1 {
	is tuple_length($magic), 2;
} pure_tuple(\$::s0, \$::s1), pure_tuple(\@::s0, \@::s1, \%::s0, \%::s1);

tm1 {
	ok tuple_slot($magic, 0) == \$::s0;
} pure_tuple(\$::s0, \$::s1), pure_tuple(\@::s0, \@::s1);
tm1 {
	ok tuple_slot(pure_tuple(\$::s0, \$::s1), $magic) == \$::s1;
} 1, 0;

tm1 {
	is_deeply [tuple_slots($magic)], [undef, undef];
} pure_tuple(undef, undef), pure_tuple();

{
	my $t0 = variable_tuple(\$::s0, \$::s1);
	my $t1 = variable_tuple(\$::s0, \$::s1);
	tm1 {
		tuple_set_slot($magic, 0, \@::s1);
		ok tuple_slot($t1, 0) == \@::s1;
	} $t1, $t0;
}
tm1 {
	my $t = variable_tuple(\$::s0, \$::s1);
	tuple_set_slot($t, $magic, \@::s0);
	ok tuple_slot($t, 1) == \@::s0;
} 1, 0;
tm1 {
	my $t = variable_tuple(\$::s0, \$::s1);
	tuple_set_slot($t, 1, $magic);
	ok tuple_slot($t, 1) == \@::s0;
} \@::s0, \@::s1;

{
	my $t0 = variable_tuple(\$::s0, \$::s1);
	my $t1 = variable_tuple(\$::s0, \$::s1);
	tm1 {
		tuple_set_slots($magic, \@::s0, \@::s1);
		ok tuple_slot($t1, 0) == \@::s0;
	} $t1, $t0;
}
tm1 {
	my $t = variable_tuple(\$::s0, \$::s1);
	tuple_set_slots($t, $magic);
	ok tuple_slot($t, 0) == \@::s0;
} \@::s0, \@::s1;
tm1 {
	my $t = variable_tuple(\$::s0, \$::s1);
	tuple_set_slots($t, $magic, \5);
	ok tuple_slot($t, 0) == \@::s0;
} \@::s0, \@::s1;
tm1 {
	my $t = variable_tuple(\$::s0, \$::s1);
	tuple_set_slots($t, \5, $magic);
	ok tuple_slot($t, 1) == \@::s0;
} \@::s0, \@::s1;

{
	my $t0 = variable_tuple(\$::s0, \$::s1);
	my $t1 = variable_tuple(\$::s0, \$::s1);
	tm1 {
		tuple_seal($magic);
		ok !tuple_mutable($t1);
	} $t1, $t0;
}

{
	package t::TiedScalar::ActOnFetch;
	sub TIESCALAR { bless({ value => $_[1], action => $_[2] }, $_[0]) }
	sub FETCH { $_[0]->{action}->(); $_[0]->{value} }
}

{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $i;
	tie $i, "t::TiedScalar::ActOnFetch", 0, sub { tuple_set_slots($t) };
	eval { tuple_slot($t, $i) };
	like $@, qr/\Atuple slot index is out of range/;
}
{
	my $t = variable_tuple();
	my $i;
	tie $i, "t::TiedScalar::ActOnFetch", 1, sub {
		tuple_set_slots($t, \$::s0, \$::s1);
	};
	ok tuple_slot($t, $i) == \$::s1;
}

{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $i;
	tie $i, "t::TiedScalar::ActOnFetch", 0, sub { tuple_seal($t) };
	eval { tuple_set_slot($t, $i, \@::s0) };
	like $@, qr/\AModification of a read-only value attempted/;
}
{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $i;
	tie $i, "t::TiedScalar::ActOnFetch", 0, sub { tuple_set_slots($t) };
	eval { tuple_set_slot($t, $i, \@::s0) };
	like $@, qr/\Atuple slot index is out of range/;
}
{
	my $t = variable_tuple();
	my $i;
	tie $i, "t::TiedScalar::ActOnFetch", 1, sub {
		tuple_set_slots($t, \$::s0, \$::s1);
	};
	ok tuple_set_slot($t, $i, \@::s0) == \@::s0;
	ok tuple_slot($t, 1) == \@::s0;
}
{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $v;
	tie $v, "t::TiedScalar::ActOnFetch", \@::s0, sub { tuple_seal($t) };
	eval { tuple_set_slot($t, 1, $v) };
	like $@, qr/\AModification of a read-only value attempted/;
}
{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $v;
	tie $v, "t::TiedScalar::ActOnFetch", \@::s0,
		sub { tuple_set_slots($t) };
	eval { tuple_set_slot($t, 1, $v) };
	like $@, qr/\Atuple slot index is out of range/;
}
{
	my $t = variable_tuple();
	my $v;
	tie $v, "t::TiedScalar::ActOnFetch", \@::s0, sub {
		tuple_set_slots($t, \$::s0, \$::s1);
	};
	tuple_set_slot($t, 1, $v);
	ok tuple_slot($t, 1) == \@::s0;
}

{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $v;
	tie $v, "t::TiedScalar::ActOnFetch", \@::s0, sub { tuple_seal($t) };
	eval { tuple_set_slots($t, $v) };
	like $@, qr/\AModification of a read-only value attempted/;
}
{
	my $t = variable_tuple(\$::s0, \$::s1);
	my $v;
	tie $v, "t::TiedScalar::ActOnFetch", \@::s0,
		sub { tuple_set_slots($t) };
	tuple_set_slots($t, $v, \@::s1);
	is tuple_length($t), 2;
	ok tuple_slot($t, 1) == \@::s1;
}

1;
