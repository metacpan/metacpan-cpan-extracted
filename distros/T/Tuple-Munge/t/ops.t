use warnings;
use strict;

use Test::More tests => 7*5 + 8 + 16 + 31 + 20 + 18 + 6 + 12 + 3*4*21*19 +
			2*5 + 11*5;

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

use Tuple::Munge qw(
	pure_tuple constant_tuple variable_tuple
	tuple_mutable tuple_length tuple_slot tuple_slots
	tuple_set_slot tuple_set_slots tuple_seal
);

my $a0 = pure_tuple();
ok !tuple_mutable($a0);
ok slot_list_eq([tuple_slots($a0)], []);
my $a1 = constant_tuple();
ok !tuple_mutable($a1);
ok slot_list_eq([tuple_slots($a1)], []);
my $a2 = variable_tuple();
ok tuple_mutable($a2);
ok slot_list_eq([tuple_slots($a2)], []);
my $a3 = variable_tuple(\1);
tuple_set_slots($a3);
ok slot_list_eq([tuple_slots($a3)], []);

my $b0 = pure_tuple(\$::s0);
ok !tuple_mutable($b0);
ok slot_list_eq([tuple_slots($b0)], [\$::s0]);
my $b1 = constant_tuple(\$::s0);
ok !tuple_mutable($b1);
ok slot_list_eq([tuple_slots($b1)], [\$::s0]);
my $b2 = variable_tuple(\$::s0);
ok tuple_mutable($b2);
ok slot_list_eq([tuple_slots($b2)], [\$::s0]);
my $b3 = variable_tuple(\1);
tuple_set_slots($b3, \$::s0);
ok slot_list_eq([tuple_slots($b3)], [\$::s0]);

my $c0 = pure_tuple(\$::s0, \@::s0);
ok !tuple_mutable($c0);
ok slot_list_eq([tuple_slots($c0)], [\$::s0, \@::s0]);
my $c1 = constant_tuple(\$::s0, \@::s0);
ok !tuple_mutable($c1);
ok slot_list_eq([tuple_slots($c1)], [\$::s0, \@::s0]);
my $c2 = variable_tuple(\$::s0, \@::s0);
ok tuple_mutable($c2);
ok slot_list_eq([tuple_slots($c2)], [\$::s0, \@::s0]);
my $c3 = variable_tuple(\1);
tuple_set_slots($c3, \$::s0, \@::s0);
ok slot_list_eq([tuple_slots($c3)], [\$::s0, \@::s0]);

my @d0 = ();
my $d1 = pure_tuple(@d0);
ok !tuple_mutable($d1);
ok slot_list_eq([tuple_slots($d1)], \@d0);
my $d2 = constant_tuple(@d0);
ok !tuple_mutable($d2);
ok slot_list_eq([tuple_slots($d2)], \@d0);
my $d3 = variable_tuple(@d0);
ok tuple_mutable($d3);
ok slot_list_eq([tuple_slots($d3)], \@d0);
my $d4 = variable_tuple(\1);
tuple_set_slots($d4, @d0);
ok slot_list_eq([tuple_slots($d4)], \@d0);

my @e0 = (\$::s0, \@::s0);
my $e1 = pure_tuple(@e0);
ok !tuple_mutable($e1);
ok slot_list_eq([tuple_slots($e1)], \@e0);
my $e2 = constant_tuple(@e0);
ok !tuple_mutable($e2);
ok slot_list_eq([tuple_slots($e2)], \@e0);
my $e3 = variable_tuple(@e0);
ok tuple_mutable($e3);
ok slot_list_eq([tuple_slots($e3)], \@e0);
my $e4 = variable_tuple(\1);
tuple_set_slots($e4, @e0);
ok slot_list_eq([tuple_slots($e4)], \@e0);

foreach my $tcode (
	sub { pure_tuple() },
	sub { pure_tuple(undef) },
	sub { pure_tuple(\3) },
	sub { pure_tuple(\3, undef) },
) {
	ok $tcode->() == $tcode->();
}
foreach my $tcode (
	sub { constant_tuple() },
	sub { variable_tuple() },
	sub { pure_tuple(\$::s0) },
	sub { pure_tuple(undef, \$::s0) },
) {
	ok $tcode->() != $tcode->();
}

my $f0 = variable_tuple(\$::s0, \@::s0);
my $f1 = 0;
is tuple_slot($f0, $f1), \$::s0;
is tuple_slot($f0, 0), \$::s0;
tuple_set_slot($f0, $f1, \$::s1);
is tuple_slot($f0, $f1), \$::s1;
tuple_set_slot($f0, 0, \$::s2);
is tuple_slot($f0, 0), \$::s2;
$f1 = 1;
is tuple_slot($f0, $f1), \@::s0;
is tuple_slot($f0, 1), \@::s0;
tuple_set_slot($f0, $f1, \@::s1);
is tuple_slot($f0, $f1), \@::s1;
tuple_set_slot($f0, 1, \@::s2);
is tuple_slot($f0, 1), \@::s2;
$f1 = 2;
eval { tuple_slot($f0, $f1) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_slot($f0, 2) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($f0, $f1, \%::s0) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($f0, 2, \%::s0) };
like $@, qr/\Atuple slot index is out of range/;
$f1 = -1;
eval { tuple_slot($f0, $f1) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_slot($f0, -1) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($f0, $f1, \%::s0) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_set_slot($f0, -1, \%::s0) };
like $@, qr/\Atuple slot index is out of range/;

is tuple_mutable(pure_tuple()), !!0;
is tuple_length(pure_tuple()), 0;
is tuple_mutable(pure_tuple(\11, \22)), !!0;
is tuple_length(pure_tuple(\11, \22)), 2;
use constant g0 => constant_tuple();
is tuple_mutable(g0), !!0;
is tuple_length(g0), 0;
my($g1, $g2, $g3, $g4) = (-1, 0, 1, 2);
use constant g5 => constant_tuple(\$::s0, \@::s0);
is tuple_mutable(g5), !!0;
is tuple_length(g5), 2;
eval { tuple_slot(g5, -1) };
like $@, qr/\Atuple slot index is out of range/;
ok tuple_slot(g5, 0) == \$::s0;
ok tuple_slot(g5, 1) == \@::s0;
eval { tuple_slot(g5, 2) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_slot(g5, $g1) };
like $@, qr/\Atuple slot index is out of range/;
ok tuple_slot(g5, $g2) == \$::s0;
ok tuple_slot(g5, $g3) == \@::s0;
eval { tuple_slot(g5, $g4) };
like $@, qr/\Atuple slot index is out of range/;
use constant g6 => variable_tuple();
is tuple_mutable(g6), !!1;
is tuple_length(g6), 0;
tuple_set_slots(g6, \$::s1, \@::s1);
is tuple_mutable(g6), !!1;
is tuple_length(g6), 2;
eval { tuple_slot(g6, -1) };
like $@, qr/\Atuple slot index is out of range/;
ok tuple_slot(g6, 0) == \$::s1;
ok tuple_slot(g6, 1) == \@::s1;
eval { tuple_slot(g6, 2) };
like $@, qr/\Atuple slot index is out of range/;
eval { tuple_slot(g6, $g1) };
like $@, qr/\Atuple slot index is out of range/;
ok tuple_slot(g6, $g2) == \$::s1;
ok tuple_slot(g6, $g3) == \@::s1;
eval { tuple_slot(g6, $g4) };
like $@, qr/\Atuple slot index is out of range/;
tuple_seal(g6);
is tuple_mutable(g6), !!0;
is tuple_length(g6), 2;
ok tuple_slot(g6, 0) == \$::s1;

our $h0 = variable_tuple(\$::s0, \@::s0);
is tuple_mutable($h0), !!1;
is tuple_length($h0), 2;
ok tuple_slot($h0, 1) == \@::s0;
ok [tuple_slots($h0)]->[1] == \@::s0;
ok tuple_set_slot($h0, 1, \%::s0) == \%::s0;
ok tuple_slot($h0, 1) == \%::s0;
is scalar(tuple_set_slots($h0)), undef;
is tuple_length($h0), 0;
ok tuple_seal($h0) == $h0;
is tuple_mutable($h0), !!0;
my $h1 = variable_tuple(\$::s1, \@::s1);
is tuple_mutable($h1), !!1;
is tuple_length($h1), 2;
ok tuple_slot($h1, 1) == \@::s1;
ok [tuple_slots($h1)]->[1] == \@::s1;
ok tuple_set_slot($h1, 1, \%::s1) == \%::s1;
ok tuple_slot($h1, 1) == \%::s1;
is scalar(tuple_set_slots($h1)), undef;
is tuple_length($h1), 0;
ok tuple_seal($h1) == $h1;
is tuple_mutable($h1), !!0;

my $i0 = pure_tuple(\$::s0, \@::s0);
is tuple_length($i0), 2;
ok tuple_slot($i0, 1) == \@::s0;
$i0 = pure_tuple(\$::s1, \@::s1);
is tuple_length($i0), 2;
ok tuple_slot($i0, 1) == \@::s1;
our $i0a = pure_tuple(\$::s2, \@::s2);
is tuple_length($i0a), 2;
ok tuple_slot($i0a, 1) == \@::s2;
my $i1 = constant_tuple(\$::s0, \@::s0);
is tuple_length($i1), 2;
ok tuple_slot($i1, 1) == \@::s0;
$i1 = constant_tuple(\$::s1, \@::s1);
is tuple_length($i1), 2;
ok tuple_slot($i1, 1) == \@::s1;
our $i1a = constant_tuple(\$::s2, \@::s2);
is tuple_length($i1a), 2;
ok tuple_slot($i1a, 1) == \@::s2;
my $i2 = variable_tuple(\$::s0, \@::s0);
is tuple_length($i2), 2;
ok tuple_slot($i2, 1) == \@::s0;
$i2 = variable_tuple(\$::s1, \@::s1);
is tuple_length($i2), 2;
ok tuple_slot($i2, 1) == \@::s1;
our $i2a = variable_tuple(\$::s2, \@::s2);
is tuple_length($i2a), 2;
ok tuple_slot($i2a, 1) == \@::s2;

my $j0 = \(my $j1 = pure_tuple(\$::s0, \@::s0));
ok $j0 == \$j1;
$j0 = undef;
$j0 = \($j1 = pure_tuple(\$::s1, \@::s1));
ok $j0 == \$j1;
my $j2 = \(my $j3 = constant_tuple(\$::s0, \@::s0));
ok $j2 == \$j3;
$j2 = undef;
$j2 = \($j3 = constant_tuple(\$::s1, \@::s1));
ok $j2 == \$j3;
my $j4 = \(my $j5 = variable_tuple(\$::s0, \@::s0));
ok $j4 == \$j5;
$j4 = undef;
$j4 = \($j5 = variable_tuple(\$::s1, \@::s1));
ok $j4 == \$j5;

package DetectDestroy {
	sub new { bless([$_[1]], __PACKAGE__) }
	sub DESTROY { ${$_[0]->[0]}++; }
}
my($k0, $k1, $k2) = (0, 0, 0);
{
	my $k3 = pure_tuple(DetectDestroy->new(\$k0));
	my $k4 = constant_tuple(DetectDestroy->new(\$k1));
	my $k5 = variable_tuple(DetectDestroy->new(\$k2));
	is $k0, 0;
	is $k1, 0;
	is $k2, 0;
}
is $k0, 1;
is $k1, 1;
is $k2, 1;
($k0, $k1, $k2) = (0, 0, 0);
my($k6, $k7, $k8);
{
	$k6 = pure_tuple(DetectDestroy->new(\$k0));
	$k7 = constant_tuple(DetectDestroy->new(\$k1));
	$k8 = variable_tuple(DetectDestroy->new(\$k2));
	is $k0, 0;
	is $k1, 0;
	is $k2, 0;
}
is $k0, 0;
is $k1, 0;
is $k2, 0;

package OverloadDeref {
	my $scalar = 123;
	my @array = (111, 222);
	my %hash = (a=>11, b=>22);
	use overload "\${}" => sub { \$scalar }, "\@{}" => sub { \@array },
		"%{}" => sub { \%hash }, "&{}" => sub { \&main::slot_value_eq },
		"*{}" => sub { \*::s0 };
}
sub new_counter_sub() { my $c = 0; sub () { ++$c } }
foreach(\*::l2, \*::l4, \*::l6, \*::l7) {}
my @l0 = (
	undef,
	\undef,
	\3,
	\(my $l1),
	[ 11, 22 ],
	{ a=>77, b=>88 },
	new_counter_sub(),
	\*::l2,
	\(my $g = *::l7),
	bless(\(my $l3), "main"),
	bless([ 33, 44 ], "main"),
	bless({ a=>99, b=>110 }, "main"),
	bless(new_counter_sub(), "main"),
	bless(\*::l4, "main"),
	bless(\(my $l5), "OverloadDeref"),
	bless([ 55, 66 ], "OverloadDeref"),
	bless({}, "OverloadDeref"),
	bless(new_counter_sub(), "OverloadDeref"),
	bless(\*::l6, "OverloadDeref"),
	*STDOUT{IO},
	variable_tuple(\3, \4),
);
sub identity($) { $_[0] }
sub kvref(@) {
	my @e;
	for(my $i = 0; $i != @_; $i += 2) {
		push @e, [ ${$_[$i]}, $_[$i+1] ];
	}
	return map { @$_ } sort { $a->[0] cmp $b->[0] } @e;
}
package DoOnFetch {
	sub TIESCALAR { bless({ act=>$_[1] }, __PACKAGE__) }
	sub FETCH { $_[0]->{act}->() }
	sub STORE {}
}
sub with_localisation($) {
	my($act) = @_;
	our $with_localisation_var;
	my $r;
	tie $with_localisation_var, "DoOnFetch", sub { $r = $act->() };
	do { local $with_localisation_var };
	untie $with_localisation_var;
	return $r;
}
sub collect_result($) {
	my($act) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	my $value = eval { $act->() } // [];
	my $error = $@;
	s/ at .*//s foreach $error, @warnings;
	return { v=>$value, e=>$error, w=>\@warnings };
}
foreach my $func_group (
	[ "",
		sub { [\${identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->$*] },
		sub { [\${tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->$*] },
		sub { [\${tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	],
	do { no strict; [ "",
		sub { [0+defined(${identity($_[0])})] },
		sub { [0+defined(tuple_slot(variable_tuple($_[0]), 0)->$*)] },
		sub { [0+defined(${tuple_slot(variable_tuple($_[0]), 0)})] },
		sub { [0+defined(tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->$*)] },
		sub { [0+defined(${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])})] },
	] },
	do { no strict; no warnings "uninitialized"; [ "",
		sub { [0+defined(${identity($_[0])})] },
		sub { [0+defined(tuple_slot(variable_tuple($_[0]), 0)->$*)] },
		sub { [0+defined(${tuple_slot(variable_tuple($_[0]), 0)})] },
		sub { [0+defined(tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->$*)] },
		sub { [0+defined(${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])})] },
	] },
	[ "",
		sub { [\@{identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->@*] },
		sub { [\@{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->@*] },
		sub { [\@{tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	],
	[ "",
		sub { [scalar @{identity($_[0])}] },
		sub { [scalar tuple_slot(variable_tuple($_[0]), 0)->@*] },
		sub { [scalar @{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [scalar tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->@*] },
		sub { [scalar @{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}] },
	],
	[ "",
		sub { [\(@{identity($_[0])})] },
		sub { [\(tuple_slot(variable_tuple($_[0]), 0)->@*)] },
		sub { [\(@{tuple_slot(variable_tuple($_[0]), 0)})] },
		sub { [\(tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->@*)] },
		sub { [\(@{tuple_set_slot(variable_tuple(undef), 0, $_[0])})] },
	],
	[ "",
		sub { [\${identity($_[0])}[1]] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->[1]] },
		sub { [\${tuple_slot(variable_tuple($_[0]), 0)}[1]] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->[1]] },
		sub { [\${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}[1]] },
	],
	[ "",
		sub { [\${identity($_[0])}[my $z = 1]] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->[my $z = 1]] },
		sub { [\${tuple_slot(variable_tuple($_[0]), 0)}[my $z = 1]] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->[my $z = 1]] },
		sub { [\${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}[my $z = 1]] },
	],
	[ "",
		sub { [\%{identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->%*] },
		sub { [\%{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->%*] },
		sub { [\%{tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	],
	[ "",
		sub { [scalar %{identity($_[0])}] },
		sub { [scalar tuple_slot(variable_tuple($_[0]), 0)->%*] },
		sub { [scalar %{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [scalar tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->%*] },
		sub { [scalar %{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}] },
	],
	[ "",
		sub { [kvref(\(%{identity($_[0])}))] },
		sub { [kvref(\(tuple_slot(variable_tuple($_[0]), 0)->%*))] },
		sub { [kvref(\(%{tuple_slot(variable_tuple($_[0]), 0)}))] },
		sub { [kvref(\(tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->%*))] },
		sub { [kvref(\(%{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}))] },
	],
	[ "",
		sub { [\${identity($_[0])}{a}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->{a}] },
		sub { [\${tuple_slot(variable_tuple($_[0]), 0)}{a}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->{a}] },
		sub { [\${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}{a}] },
	],
	[ "",
		sub { [\${identity($_[0])}{my $z = "a"}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->{my $z = "a"}] },
		sub { [\${tuple_slot(variable_tuple($_[0]), 0)}{my $z = "a"}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->{my $z = "a"}] },
		sub { [\${tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}{my $z = "a"}] },
	],
	[ "",
		sub { [\&{identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->&*] },
		sub { [\&{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->&*] },
		sub { [\&{tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	],
	do { no warnings "uninitialized"; [ "",
		sub { [\&{identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->&*] },
		sub { [\&{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->&*] },
		sub { [\&{tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	] },
	[ "",
		sub { my $v = $_[0]; [with_localisation sub {
			\&{identity($v)} }] },
		sub { my $v = $_[0]; [with_localisation sub {
			\tuple_slot(variable_tuple($v), 0)->&* }] },
		sub { my $v = $_[0]; [with_localisation sub {
			\&{tuple_slot(variable_tuple($v), 0)} }] },
		sub { my $v = $_[0]; [with_localisation sub {
			\tuple_set_slot(variable_tuple(undef), 0,
			$v)->&* }] },
		sub { my $v = $_[0]; [with_localisation sub {
			\&{tuple_set_slot(variable_tuple(undef), 0,
			$v)} }] },
	],
	[ "nofakeglob,noio",
		sub { [\*{identity($_[0])}] },
		sub { [\tuple_slot(variable_tuple($_[0]), 0)->**] },
		sub { [\*{tuple_slot(variable_tuple($_[0]), 0)}] },
		sub { [\tuple_set_slot(variable_tuple(undef), 0, $_[0])->**] },
		sub { [\*{tuple_set_slot(variable_tuple(undef), 0, $_[0])}] },
	],
	[ "",
		((sub { [*{identity($_[0])}{IO} // 0] }) x 3),
		sub { [*{tuple_slot(variable_tuple($_[0]), 0)}{IO} // 0] },
		sub { [*{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])->**}{IO} // 0] },
	],
	[ "",
		sub { [*{\*{identity($_[0])}}{IO} // 0] },
		sub { [*{\tuple_slot(variable_tuple($_[0]), 0)->**}{IO} // 0] },
		sub { [*{\*{tuple_slot(variable_tuple($_[0]), 0)}}{IO} // 0] },
		sub { [*{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}{IO} // 0] },
		sub { [*{\*{tuple_set_slot(variable_tuple(undef), 0,
			$_[0])}}{IO} // 0] },
	],
) {
	my($gflags, $control_func, @subject_func) = @$func_group;
	foreach my $slot_value (@l0) {
		if(($gflags =~ /\bnoio\b/ &&
				ref($slot_value) =~ /\AIO(?:::File)?\z/) ||
			($gflags =~ /\bnofakeglob\b/ &&
				ref($slot_value) eq "GLOB" &&
				\*$slot_value != $slot_value)) {
			ok 1 for 1..(3*@subject_func);
			next;
		}
		my $control_result =
			collect_result(sub { $control_func->($slot_value) });
		foreach my $subject_func (@subject_func) {
			my $subject_result = collect_result(
					sub { $subject_func->($slot_value) });
			is $subject_result->{e}, $control_result->{e};
			is_deeply $subject_result->{w}, $control_result->{w};
			ok @{$subject_result->{v}} == @{$control_result->{v}} &&
				!(grep {
					my $s = $subject_result->{v}->[$_];
					my $c = $control_result->{v}->[$_];
					!(ref($s) eq ref($c) &&
						(ref($c) eq "" ? $s eq $c :
							$s == $c));
				} 0..$#{$control_result->{v}});
		}
	}
}

foreach my $func (
	sub { \&{identity($_[0])} },
	sub { \tuple_slot(variable_tuple($_[0]), 0)->&* },
	sub { \&{tuple_slot(variable_tuple($_[0]), 0)} },
	sub { \tuple_set_slot(variable_tuple(undef), 0, $_[0])->&* },
	sub { \&{tuple_set_slot(variable_tuple(undef), 0, $_[0])} },
) {
	use feature "state";
	state $n = 0;
	my $gvref = do { no strict "refs"; \*{"m$n"} };
	my $result = $func->($gvref);
	ok ref($result) eq "CODE";
	ok $result == do { no strict "refs"; \&{"m$n"} };
	$n++;
}

foreach my $func (
	sub { \*{identity($_[0])} },
	sub { \tuple_slot(variable_tuple($_[0]), 0)->** },
	sub { \*{tuple_slot(variable_tuple($_[0]), 0)} },
	sub { \tuple_set_slot(variable_tuple(undef), 0, $_[0])->** },
	sub { \*{tuple_set_slot(variable_tuple(undef), 0, $_[0])} },
) {
	my $result = $func->(*STDOUT{IO});
	ok ref($result) eq "GLOB";
	ok *{$result}{IO} eq *STDOUT{IO};
	ok $$result eq ${\*{*STDOUT{IO}}};
	my $g = *n0;
	$result = $func->(\$g);
	ok ref($result) eq "GLOB";
	ok $result != \$g;
	ok $result != \*n0;
	my $p;
	*n0 = \$p;
	ok *n0{SCALAR} == \$p;
	ok *{$g}{SCALAR} == \$p;
	ok *{$result}{SCALAR} == \$p;
	ok $$result eq ${\*n0};
	ok \*$result == $result;
}

1;
