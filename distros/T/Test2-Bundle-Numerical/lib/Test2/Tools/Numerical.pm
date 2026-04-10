package Test2::Tools::Numerical;
use strict;
use warnings;
use Test2::API qw/context/;
use Test2::Tools::Basic qw(ok diag done_testing skip skip_all todo pass fail);
use Test2::Tools::Subtest qw(subtest_buffered);
use Scalar::Util qw(looks_like_number);
use overload ();
use Exporter 'import';
use Config;

our $VERSION = '0.03';

our @EXPORT = qw(
	ok is isnt is_deeply subtest diag plan done_testing skip skip_all todo pass fail like use_ok
	is_lt is_lte is_gt is_gte
	approx_eq approx_ok vec_approx_eq vec_is vec_ok vec_isnt vec_ne
	within_tolerance within_tol
	is_quadmath is_long_double is_infinite is_finite get_tolerance
	float_is float_isnt float_ne float_is_abs float_is_ulps float_is_relative
	float_ok float_cmp
	ulp_equal ulp_distance
	relatively_equal relative_tolerance
	bits_equal bits_ok bits_compare bits_diff bits_hex
	nan_ok nan_equal nan_is
	nv_info nv_epsilon nv_digits
);

our @EXPORT_OK = @EXPORT;

our $NUMERIC_FAILURE = 0;
our $NUMERIC_FAILURE_NAME;
our $NUMERIC_FAILURE_GOT;
our $NUMERIC_FAILURE_EXPECTED;
our $NUMERIC_FAILURE_METHOD;
our $NUMERIC_FAILURE_DETAILS;

our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	basic => [qw(
		ok diag plan done_testing skip skip_all todo pass fail like use_ok subtest
		is_lt is_lte is_gt is_gte
	)],
	ulp => [qw(ulp_equal ulp_distance)],
	bits => [qw(bits_equal bits_ok bits_compare bits_diff bits_hex)],
	nan => [qw(nan_ok nan_equal nan_is is_infinite is_finite)],
	vector => [qw(vec_approx_eq vec_is vec_ok vec_isnt vec_ne)],
);

sub subtest {
	return subtest_buffered(@_);
}

sub plan ($;@) {
	my $plan = shift;

	if (defined $plan && $plan eq 'tests') {
		$plan = shift;
	}
	elsif (defined $plan && $plan eq 'skip_all') {
		skip_all(@_);
		return;
	}

	my $ctx = context();
	$ctx->plan($plan);
	$ctx->release;
}

our %NV_INFO;
BEGIN {
	my $nvtype = $Config{nvtype} || 'double';
	my $nvsize = $Config{nvsize} || 8;

	my $is_quadmath = ($nvtype eq '__float128') ? 1 : 0;
	my $is_long_double = ($nvtype =~ /long\s*double/i) ? 1 : 0;
	my $is_double = ($nvtype eq 'double') ? 1 : 0;

	%NV_INFO = (
		type => $nvtype,
		size => $nvsize,
		is_quadmath    => $is_quadmath,
		is_long_double => $is_long_double,
		is_double      => $is_double,
	);

	if ($is_quadmath) {
		$NV_INFO{mantissa_bits} = 113;
		$NV_INFO{digits} = 34;
		$NV_INFO{epsilon} = 2 ** -112;
	} elsif ($is_long_double) {
		if ($nvsize >= 16) {
			$NV_INFO{mantissa_bits} = 113;
			$NV_INFO{digits} = 34;
			$NV_INFO{epsilon} = 2 ** -112;
		} else {
			$NV_INFO{mantissa_bits} = 64;
			$NV_INFO{digits} = 21;
			$NV_INFO{epsilon} = 2 ** -63;
		}
	} else {
		$NV_INFO{mantissa_bits} = 53;
		$NV_INFO{digits} = 17;
		$NV_INFO{epsilon} = 2 ** -52;
	}

	my $eps = 1.0;
	$eps /= 2 while (1.0 + $eps/2) != 1.0;
	$NV_INFO{machine_epsilon} = $eps;
}

sub nv_info    { return \%NV_INFO }
sub nv_epsilon { return $NV_INFO{machine_epsilon} }
sub nv_digits  { return $NV_INFO{digits} }

sub is_quadmath {
	my $name = @_ == 1 ? pop(@_) : undef;
	return _maybe_test($NV_INFO{is_quadmath}, $name);
}

sub is_long_double {
	my $name = @_ == 1 ? pop(@_) : undef;
	return _maybe_test($NV_INFO{is_long_double}, $name);
}

sub get_tolerance {
	my ($strict) = @_;
	if ($NV_INFO{is_quadmath}) {
		return $strict ? 1e-30 : 1e-12;
	} elsif ($NV_INFO{is_long_double}) {
		return $strict ? 1e-18 : 1e-12;
	}
	return $strict ? 1e-14 : 1e-9;
}

sub relative_tolerance {
	my ($ulps) = @_;
	$ulps //= 4;
	return $NV_INFO{machine_epsilon} * $ulps;
}

sub _note_numeric_failure {
	my %args = @_;
	$NUMERIC_FAILURE = 1;
	$NUMERIC_FAILURE_NAME = $args{name} if exists $args{name};
	$NUMERIC_FAILURE_GOT = $args{got} if exists $args{got};
	$NUMERIC_FAILURE_EXPECTED = $args{expected} if exists $args{expected};
	$NUMERIC_FAILURE_METHOD = $args{method} if exists $args{method};
	$NUMERIC_FAILURE_DETAILS = $args{details} if exists $args{details};
}

sub _maybe_test {
	my ($result, $name) = @_;
	return $result unless defined $name;
	ok($result, $name);
	return $result;
}

sub _looks_like_int {
	my ($val) = @_;
	return 0 if ref($val);
	return $val =~ /^[-+]?\d+$/ ? 1 : 0;
}

sub _should_numeric_compare {
	my ($got, $expected) = @_;
	return 0 if ref($got) || ref($expected);
	return 0 unless defined $got && defined $expected;
	return 1 if looks_like_number($got) && looks_like_number($expected);
	return 0;
}

sub _numerical_scalar_equal {
	my ($got, $expected) = @_;
	return 1 if !defined $got && !defined $expected;
	return 0 if !defined $got || !defined $expected;
	if (_looks_like_int($got) && _looks_like_int($expected)) {
		return "" . $got eq "" . $expected;
	}
	return relatively_equal($got, $expected, 4);
}

sub _deep_equal {
	my ($got, $expected) = @_;
	return 1 if !defined $got && !defined $expected;
	return 0 if !defined $got || !defined $expected;

	my $rg = ref($got);
	my $re = ref($expected);
	return 0 if $rg ne $re;

	if (!$rg) {
		return _numerical_scalar_equal($got, $expected);
	}

	if ($rg eq 'ARRAY') {
		return 0 unless @$got == @$expected;
		for my $i (0 .. $#$got) {
			return 0 unless _deep_equal($got->[$i], $expected->[$i]);
		}
		return 1;
	}

	if ($rg eq 'HASH') {
		my @kg = sort keys %$got;
		my @ke = sort keys %$expected;
		return 0 unless @kg == @ke;
		for my $i (0 .. $#kg) {
			return 0 unless $kg[$i] eq $ke[$i];
			return 0 unless _deep_equal($got->{$kg[$i]}, $expected->{$ke[$i]});
		}
		return 1;
	}

	if ($rg eq 'SCALAR' || $rg eq 'REF') {
		return _deep_equal($$got, $$expected);
	}

	if (overload::Method($got, '==') && overload::Method($expected, '==')) {
		return $got == $expected;
	}

	if (overload::Method($got, '""') && overload::Method($expected, '""')) {
		return "" . $got eq "" . $expected;
	}

	return 0;
}

sub is ($$;$) {
	my ($got, $expected, $name) = @_;
	if (_should_numeric_compare($got, $expected)) {
		my $ok = _numerical_scalar_equal($got, $expected);
		ok($ok, $name);
		unless ($ok) {
			diag("  got:      " . (defined $got ? $got : 'undef'));
			diag("  expected: " . (defined $expected ? $expected : 'undef'));
		}
		return $ok;
	}

	my $ok = defined $got && defined $expected ? $got eq $expected : !defined $got && !defined $expected;
	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub isnt ($$;$) {
	my ($got, $expected, $name) = @_;
	my $ok;
	if (_should_numeric_compare($got, $expected)) {
		$ok = !_numerical_scalar_equal($got, $expected);
	}
	else {
		$ok = defined $got && defined $expected ? $got ne $expected : defined $got || defined $expected;
	}

	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub is_lt {
	my ($got, $expected, $name) = @_;
	my $ok = defined $got && defined $expected && $got < $expected;
	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub is_lte {
	my ($got, $expected, $name) = @_;
	my $ok = defined $got && defined $expected && $got <= $expected;
	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub is_gt {
	my ($got, $expected, $name) = @_;
	my $ok = defined $got && defined $expected && $got > $expected;
	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub is_gte {
	my ($got, $expected, $name) = @_;
	my $ok = defined $got && defined $expected && $got >= $expected;
	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub is_deeply ($$;$) {
	my ($got, $expected, $name) = @_;
	my $ok = _deep_equal($got, $expected);
	ok($ok, $name);
	unless ($ok) {
		diag('  deep structures differ');
	}
	return $ok;
}

sub like {
	my ($got, $re, $name) = @_;
	my $ok = defined $got && defined $re && $got =~ $re;
	my $ctx = context();
	$ctx->ok($ok, $name);
	$ctx->release;
	return $ok;
}

sub use_ok {
	my ($module, @args) = @_;
	my $version;
	if (@args && defined $args[0] && $args[0] =~ /^[0-9_]+(?:\.[0-9_]+)*$/) {
		$version = shift @args;
	}

	my $ok = 1;
	my $err;
	my $file = $module;
	$file =~ s{::}{/}g;
	$file .= '.pm';
	eval { require $file; 1 } or do { $ok = 0; $err = $@; };

	if ($ok && defined $version) {
		eval { $module->VERSION($version); 1 } or do { $ok = 0; $err = $@; };
	}

	if ($ok && @args) {
		eval { $module->import(@args); 1 } or do { $ok = 0; $err = $@; };
	}

	ok($ok, "use_ok($module)");
	diag("  $err") unless $ok;
	return $ok;
}

# 1. Absolute tolerance (original method)
sub approx_eq {
	my $name = @_ == 4 ? pop(@_) : undef;
	my ($got, $expected, $tolerance) = @_;
	$tolerance //= get_tolerance();
	return _maybe_test(1, $name) if !defined $got && !defined $expected;
	return _maybe_test(0, $name) if !defined $got || !defined $expected;
	my $ok = abs($got - $expected) < $tolerance;
	_note_numeric_failure(
		name     => $name,
		got      => $got,
		expected => $expected,
		method   => 'absolute',
		details  => sprintf('diff: %g, tolerance: %g', abs($got - $expected), $tolerance),
	) unless $ok;
	return _maybe_test($ok, $name);
}

sub relatively_equal {
	my $name = @_ == 4 ? pop(@_) : undef;
	my ($got, $expected, $ulps) = @_;
	$ulps //= 4;

	return _maybe_test(1, $name) if !defined $got && !defined $expected;
	return _maybe_test(0, $name) if !defined $got || !defined $expected;
	if ($expected == 0) {
		my $ok = $got == 0;
		_note_numeric_failure(
			name     => $name,
			got      => $got,
			expected => $expected,
			method   => 'relative',
			details  => sprintf('expected is zero, got: %g', $got),
		) unless $ok;
		return _maybe_test($ok, $name);
	}

	if ($got == 0) {
		my $ok = $expected == 0;
		_note_numeric_failure(
			name     => $name,
			got      => $got,
			expected => $expected,
			method   => 'relative',
			details  => sprintf('got is zero, expected: %g', $expected),
		) unless $ok;
		return _maybe_test($ok, $name);
	}

	if ($got != $got || $expected != $expected) {
		my $ok = $got == $expected;
		_note_numeric_failure(
			name     => $name,
			got      => $got,
			expected => $expected,
			method   => 'relative',
			details  => 'NaN comparison',
		) unless $ok;
		return _maybe_test($ok, $name);
	}

	my $max_abs = abs($got) > abs($expected) ? abs($got) : abs($expected);
	my $diff = abs($got - $expected);
	my $ok = $diff <= $NV_INFO{machine_epsilon} * $max_abs * $ulps;
	_note_numeric_failure(
		name     => $name,
		got      => $got,
		expected => $expected,
		method   => 'relative',
		details  => sprintf('diff: %g, max allowed: %g', $diff, $NV_INFO{machine_epsilon} * $max_abs * $ulps),
	) unless $ok;
	return _maybe_test($ok, $name);
}

sub ulp_distance {
	my ($a, $b, $op, $rhs, $name) = @_;

	return 0 if !defined $a && !defined $b;
	return -1 if !defined $a || !defined $b;
	return 0 if $a == $b;
	return -1 if $a != $a || $b != $b;

	my $max_abs = abs($a) > abs($b) ? abs($a) : abs($b);
	$max_abs = 1.0 if $max_abs == 0;
	my $dist = int(abs($a - $b) / ($NV_INFO{machine_epsilon} * $max_abs) + 0.5);

	return $dist unless defined $op;

	my %operators = (
		eq  => sub { $_[0] == $_[1] },
		ne  => sub { $_[0] != $_[1] },
		lt  => sub { $_[0] <  $_[1] },
		le  => sub { $_[0] <= $_[1] },
		lte => sub { $_[0] <= $_[1] },
		gt  => sub { $_[0] >  $_[1] },
		ge  => sub { $_[0] >= $_[1] },
		gte => sub { $_[0] >= $_[1] },
	);

	my $cmp = $operators{lc $op}
	or die "Unknown comparison operator '$op' for ulp_distance";

	my $ok = $cmp->($dist, $rhs);
	_note_numeric_failure(
		name     => $name,
		got      => $dist,
		expected => $rhs,
		method   => 'ulp_distance',
		details  => sprintf('ULP distance: %d, %s %s', $dist, $op, $rhs),
	) unless $ok;

	return _maybe_test($ok, $name);
}

sub ulp_equal {
	my $name = @_ == 4 ? pop(@_) : undef;
	my ($got, $expected, $max_ulps) = @_;
	$max_ulps //= 4;

	my $dist = ulp_distance($got, $expected);
	return _maybe_test(0, $name) if $dist < 0;
	my $ok = $dist <= $max_ulps;
	_note_numeric_failure(
		name     => $name,
		got      => $got,
		expected => $expected,
		method   => 'ulp',
		details  => sprintf('ULP distance: %d, max allowed: %d', $dist, $max_ulps),
	) unless $ok;
	return _maybe_test($ok, $name);
}

sub bits_equal {
	my $name = @_ == 3 ? pop(@_) : undef;
	my ($a, $b) = @_;
	return _maybe_test(0, $name) if !defined $a || !defined $b;
	my $ok = pack("F", $a) eq pack("F", $b);
	_note_numeric_failure() unless $ok;
	return _maybe_test($ok, $name);
}

sub bits_hex {
	my ($val) = @_;
	return 'undef' unless defined $val;
	return unpack("H*", pack("F", $val));
}

sub _float_compare {
	my ($got, $expected, $opts) = @_;
	$opts //= {};

	my $method = $opts->{method} // 'relative';
	my $ulps = $opts->{ulps} // 4;
	my $tolerance = $opts->{tolerance};

	if ($method eq 'exact') {
		my $ok = bits_equal($got, $expected);
		return ($ok, sprintf("got bits: %s, expected bits: %s", bits_hex($got), bits_hex($expected)), $method);
	}
	elsif ($method eq 'ulp') {
		my $dist = ulp_distance($got, $expected);
		my $ok = $dist >= 0 && $dist <= $ulps;
		_note_numeric_failure() unless $ok;
		return ($ok, sprintf("ULP distance: %d (max allowed: %d)", $dist, $ulps), $method);
	}
	elsif ($method eq 'absolute') {
		$tolerance //= get_tolerance();
		my $ok = approx_eq($got, $expected, $tolerance);
		return ($ok, sprintf("diff: %g, tolerance: %g", abs(($got // 0) - ($expected // 0)), $tolerance), $method);
	}

	my $ok = relatively_equal($got, $expected, $ulps);
	my $details = '';
	if (defined $got && defined $expected && $expected != 0) {
		my $rel_err = abs($got - $expected) / abs($expected);
		$details = sprintf("relative error: %g, max allowed: %g", $rel_err, $NV_INFO{machine_epsilon} * $ulps);
	}
	return ($ok, $details, $method);
}

sub float_is {
	my ($got, $expected, $name, $opts) = @_;
	my ($ok, $details, $method) = _float_compare($got, $expected, $opts);

	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
		diag("  method:   $method");
		diag("  $details") if $details;
		diag("  NV type:  $NV_INFO{type} ($NV_INFO{digits} digits)");
	}

	return $ok;
}

sub float_isnt {
	my ($got, $expected, $name, $opts) = @_;
	my ($ok, $details, $method) = _float_compare($got, $expected, $opts);
	$ok = !$ok;

	ok($ok, $name);
	unless ($ok) {
		diag("  got:      " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
		diag("  method:   $method");
		diag("  $details") if $details;
		diag("  NV type:  $NV_INFO{type} ($NV_INFO{digits} digits)");
	}

	return $ok;
}

sub float_ne { return float_isnt(@_); }

sub float_is_abs {
	my ($got, $expected, $name, $tolerance) = @_;
	return float_is($got, $expected, $name, { method => 'absolute', tolerance => $tolerance });
}

sub float_is_ulps {
	my ($got, $expected, $name, $ulps) = @_;
	return float_is($got, $expected, $name, { method => 'ulp', ulps => $ulps // 4 });
}

sub float_is_relative {
	my ($got, $expected, $name, $ulps) = @_;
	return float_is($got, $expected, $name, { method => 'relative', ulps => $ulps // 4 });
}

sub float_ok {
	my ($got, $expected, $name, $ulps) = @_;
	return float_is($got, $expected, $name, { ulps => $ulps // 4 });
}

sub float_cmp {
	my ($a, $b, $ulps) = @_;
	$ulps //= 4;
	return 0 if relatively_equal($a, $b, $ulps);
	return $a <=> $b;
}

sub is_infinite {
	my $name = @_ == 2 ? pop(@_) : undef;
	my ($x) = @_;
	return _maybe_test(0, $name) unless defined $x;
	return _maybe_test(0, $name) if $x != $x;
	my $inf = 1e999;
	return _maybe_test($x == $inf || $x == -$inf, $name);
}

sub is_finite {
	my $name = @_ == 2 ? pop(@_) : undef;
	my ($x) = @_;
	return _maybe_test(0, $name) unless defined $x;
	return _maybe_test(0, $name) if $x != $x;
	return _maybe_test(!is_infinite($x), $name);
}

sub nan_equal {
	my $name = @_ == 3 ? pop(@_) : undef;
	my ($a, $b) = @_;
	return _maybe_test(1, $name) if !defined $a && !defined $b;
	return _maybe_test(0, $name) if !defined $a || !defined $b;
	return _maybe_test(1, $name) if $a != $a && $b != $b;
	return _maybe_test($a == $b, $name);
}

sub nan_ok {
	my ($val, $name) = @_;
	my $ok = defined $val && $val != $val;
	ok($ok, $name);
	diag("  not NaN") unless $ok;
	return $ok;
}

sub nan_is {
	my ($got, $expected, $name) = @_;
	my $ok = nan_equal($got, $expected);
	ok($ok, $name);
	unless ($ok) {
		diag("  got: " . (defined $got ? $got : 'undef'));
		diag("  expected: " . (defined $expected ? $expected : 'undef'));
	}
	return $ok;
}

sub vec_approx_eq {
	my $name = @_ == 3 ? pop(@_) : undef;
	my ($v1, $v2, $tolerance) = @_;
	$tolerance //= get_tolerance();

	return _maybe_test(0, $name) unless $v1->len() == $v2->len();

	my $a1 = $v1->to_array();
	my $a2 = $v2->to_array();

	for my $i (0 .. $#$a1) {
		return _maybe_test(0, $name) unless approx_eq($a1->[$i], $a2->[$i], $tolerance);
	}
	return _maybe_test(1, $name);
}

sub vec_is {
	my ($v1, $v2, $name, $tolerance) = @_;
	my $ok = vec_approx_eq($v1, $v2, $tolerance);
	ok($ok, $name);
	diag("  vectors differ") unless $ok;
	return $ok;
}

sub vec_ok { return vec_is(@_); }

sub vec_isnt {
	my ($v1, $v2, $name, $tolerance) = @_;
	my $ok = !vec_approx_eq($v1, $v2, $tolerance);
	ok($ok, $name);
	diag("  vectors are equal") unless $ok;
	return $ok;
}

sub vec_ne { return vec_isnt(@_); }

sub approx_ok { return approx_eq(@_); }

sub within_tol { return within_tolerance(@_); }

sub bits_ok {
	my ($a, $b, $name) = @_;
	my $ok = bits_equal($a, $b);
	ok($ok, $name);
	unless ($ok) {
		diag("  got bits:      " . bits_hex($a));
		diag("  expected bits: " . bits_hex($b));
	}
	return $ok;
}

sub bits_compare {
	my ($a, $b) = @_;
	my $bits_a = bits_hex($a);
	my $bits_b = bits_hex($b);
	return 0 if $bits_a eq $bits_b;
	return $bits_a lt $bits_b ? -1 : 1;
}

sub bits_diff {
	my ($a, $b) = @_;
	return sprintf("%s vs %s", bits_hex($a), bits_hex($b));
}

sub within_tolerance {
	my ($got, $expected, $name, $tolerance) = @_;
	return float_is($got, $expected, $name, {
		method => 'absolute',
		tolerance => $tolerance,
	});
}

package
	Test2::API::Context;

sub numerical {
	return {
		nv_info            => Test2::Tools::Numerical::nv_info(),
		nv_epsilon         => Test2::Tools::Numerical::nv_epsilon(),
		relative_tolerance => Test2::Tools::Numerical::relative_tolerance(4),
		default_tolerance  => Test2::Tools::Numerical::get_tolerance(),
		numeric_failure    => {
			active   => $Test2::Tools::Numerical::NUMERIC_FAILURE,
			method   => $Test2::Tools::Numerical::NUMERIC_FAILURE_METHOD,
			got      => $Test2::Tools::Numerical::NUMERIC_FAILURE_GOT,
			expected => $Test2::Tools::Numerical::NUMERIC_FAILURE_EXPECTED,
			details  => $Test2::Tools::Numerical::NUMERIC_FAILURE_DETAILS,
		},
	};
}

1;
