use warnings;
use strict;

use Test::More tests => 30;

BEGIN {
	use_ok "Time::UTC::Now",
		qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);
}

my @rat = now_utc_rat();
is scalar(@rat), 3;
isa_ok $rat[0], "Math::BigRat";
ok $rat[0]->is_int;
isa_ok $rat[1], "Math::BigRat";
ok $rat[1] >= 0;
ok $rat[1] < 86401;
SKIP: {
	skip "no inaccuracy bound", 2 unless defined $rat[2];
	isa_ok $rat[2], "Math::BigRat";
	ok $rat[2] >= 0;
}

sub is_int($) {
	my($arg) = @_;
	return 0 unless ref(\$arg) eq "SCALAR" && defined($arg);
	return $arg =~ /\A(?:0|-?[1-9][0-9]*)\z/;
}

sub is_sna($) {
	my($arg) = @_;
	return 0 unless ref($arg) eq "ARRAY" && @$arg == 3;
	foreach(@$arg) {
		return 0 unless is_int($_);
	}
	return 0 unless $arg->[1] >= 0 && $arg->[1] < 1000000000;
	return 0 unless $arg->[2] >= 0 && $arg->[2] < 1000000000;
	return 1;
}

my @sna = now_utc_sna();
is scalar(@sna), 3;
ok is_int($sna[0]);
ok is_sna($sna[1]);
ok $sna[1]->[0] >= 0;
ok $sna[1]->[0] < 86401;
SKIP: {
	skip "no inaccuracy bound", 2 unless defined $sna[2];
	ok is_sna($sna[2]);
	ok $sna[2]->[0] >= 0;
}

sub is_num($) {
	my($arg) = @_;
	return 0 unless ref(\$arg) eq "SCALAR" && defined($arg);
	my $warned;
	local $SIG{__WARN__} = sub { $warned = 1; };
	{ no warnings "void"; 0 + $arg; }
	return !$warned;
}

my @flt = now_utc_flt();
is scalar(@flt), 3;
ok is_int($flt[0]);
ok is_num($flt[1]);
ok $flt[1] >= 0;
ok $flt[1] < 86401;
SKIP: {
	skip "no inaccuracy bound", 2 unless defined $flt[2];
	ok is_num($flt[2]);
	ok $flt[2] >= 0;
}

sub is_dec($) {
	my($arg) = @_;
	return 0 unless ref(\$arg) eq "SCALAR" && defined($arg);
	return $arg =~ /\A(?:-(?!0\z))?(?:0|[1-9][0-9]*)(?:\.[0-9]*[1-9])?\z/;
}

my @dec = now_utc_dec();
is scalar(@dec), 3;
ok is_int($dec[0]);
ok is_dec($dec[1]);
ok $dec[1] !~ /\A-/;
ok +(split(/\./, $dec[1]))[0] < 86401;
SKIP: {
	skip "no inaccuracy bound", 2 unless defined $dec[2];
	ok is_dec($dec[2]);
	ok $dec[2] !~ /\A-/;
}

1;
