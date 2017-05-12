our $tests;
our $have_sc;
our $testdir;
BEGIN {
	$tests = 16;
}
use Test::More tests => $tests;
BEGIN {
	use_ok 'Tie::StorableDir';
	$testdir = 'Tie-StorableDir-backing.t';
	eval {
		require File::Path;
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath($testdir, 0, 0700);
	};
	if ($@) {
		SKIP: {
			skip 'Need File::Path', $tests - 1;
		}
		exit 0;
	}
	eval {
		require Struct::Compare;
		import Struct::Compare;
	};
	$have_sc = !$@;
}

my %hash;
tie %hash, 'Tie::StorableDir', dirname => $testdir;

$hash{scalarref} = \undef;
$$hash{scalarref} = 42;
ok($$hash{scalarref} == 42, 'Backed scalar references');

$hash{arrayref} = [1,2];
$hash{arrayref}[2] = 42;
push @{$hash{arrayref}}, 43;
ok(@{$hash{arrayref}} == 4, 'Backed array size, set, push');
ok(pop @{$hash{arrayref}} == 43, 'Backed array pop');
ok(exists $hash{arrayref}[2], 'Backed array exists');
unshift @{$hash{arrayref}}, 43;
ok(shift @{$hash{arrayref}} == 43, 'Backed array shift/unshift');
SKIP: {
	skip 'Need Struct::Compare', 2 unless $have_sc;
	my @r = splice @{$hash{arrayref}}, 0, 2, 2, 1;
	my @e = (1, 2);
	my @e2 = (2, 1, 42);
	ok(compare(\@r, \@e), 'Backed array splice');
	ok(compare(\@{$hash{arrayref}}, \@e2), 'Backed array splice');
}
@{$hash{arrayref}} = ();
ok(@{$hash{arrayref}} == 0, 'Backed array clear');

$hash{hashref} = {
	foo => 'bar',
};
$hash{hashref}{bar} = 'baz';
ok($hash{hashref}{bar} eq 'baz', 'Backed hash');
ok($hash{hashref}{foo} eq 'bar', 'Backed hash');

my $persist = $hash{hashref};
$hash{hashref}{quux} = 42;
ok($persist->{quux} == 42, 'Backed hash persistent references');

undef $persist;
$persist = $hash{hashref};
$persist->{test} = 42;

untie %hash;
$persist->{quux} = 43;
tie %hash, 'Tie::StorableDir', dirname => $testdir;

ok($hash{hashref}{test} == 42, 'Commit on untie');
ok($hash{hashref}{quux} == 42, 'Disconnect on untie');

$persist = $hash->{hashref};
$hash->{hashref} = {};
$persist->{foo} = 42;
$persist->{bar} = {};

ok(!defined $hash->{hashref}{foo}, 'Disconnect on store');
ok(ref $persist->{bar} eq 'HASH', 'Disconnected operations');

eval {
	# tidy up after ourselves
	File::Path::rmtree($testdir, 0, 0);
}
