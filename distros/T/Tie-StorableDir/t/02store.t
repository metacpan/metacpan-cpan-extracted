#########################
my $have_sc;
our $tests;
BEGIN {
	$tests = 11;
};
use Test::More tests => $tests;
BEGIN {
	eval {
		require File::Path;
	};
	if ($@) {
		SKIP: {
			skip 'Need File::Path', $tests;
		}
		exit 0;
	}
	eval {
		require Struct::Compare;
		import Struct::Compare;
	};
	$have_sc = !$@;
	use_ok 'Tie::StorableDir';
}

my $testdir = 'StorableDir-testdir';
eval {
	File::Path::rmtree($testdir, 0, 0);
	File::Path::mkpath($testdir, 0, 0700);
};
if ($@) {
	SKIP: {
		skip "Can't clear test tree: $@", $tests - 1;
	}
	exit 0;
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %hash;
tie %hash, 'Tie::StorableDir', dirname => $testdir;

$hash{scalar} = 42;
ok($hash{scalar} == 42, 'Integer scalars');

$hash{string} = 'Hello, world';
ok($hash{string} eq 'Hello, world', 'String scalars');

$hash{undef} = undef;
ok(exists $hash{undef} && !defined $hash{undef}, 'Undef values');

{
	my $testarray = [1, 2, 3];
	$hash{array} = $testarray;
	my $ok = 1;
	my $result = $hash{array};
	$ok = 0 if (scalar @$testarray != scalar @$result);
	if ($ok) {
		LOOP: for (my $i = 0; $i < @$result; $i++) {
			if ($result->[$i] != $testarray->[$i]) {
				$ok = 0;
				last LOOP;
			}
		}
	}
	ok($ok, 'Arrayrefs');
}

SKIP: {
	$hash{hash} = 'dummy';
	skip 'Need Struct::Compare', 1 unless $have_sc;
	my $scalar = 42;
	my $htest = {
		string => 'bar',
		array => [1, 2, 3, 4],
		undef => undef,
		hash => {
			foo => 'bar',
		},
		scalarref => \$scalar
	};
	$hash{hash} = $htest;
	my $hres = $hash{hash};
	ok(compare($htest, $hres), 'Hash storage');
}

my $escapekey = "escape_test \0\t//test";
$hash{$escapekey} = 'ok';
ok($hash{$escapekey} eq 'ok', 'Escaping');

my @keys = sort keys %hash;
my @check = sort (qw(array scalar string hash undef), $escapekey);

ok(join('\0', @keys) eq join('\0', @check), "keys");

my $k = shift @check;
my $v1 = $hash{$k};
my $v2 = delete $hash{$k};

SKIP: {
	skip 'Need Struct::Compare', 1 unless $have_sc;
	ok(compare($v1, $v2), 'delete return value');
}

ok(!exists $hash{$k}, 'delete');

%hash = ();

ok(keys %hash == 0, 'Clear');

eval {
	# tidy up after ourselves
	File::Path::rmtree($testdir, 0, 0);
}

