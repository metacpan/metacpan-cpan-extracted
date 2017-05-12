our $have_sc;
our $tests;
our $testdir;
BEGIN {
	$testdir = 'StorableDir-testdir';
	$tests = 9;
}
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
	eval {
		File::Path::rmtree($testdir, 0, 0);
	};
	if ($@) {
		SKIP: {
			skip "Can't clear test tree: $@", $tests;
		}
		exit 0;
	}
	use_ok 'Tie::StorableDir';
}

SKIP: {
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath($testdir, 0, 0100);
	};
	if ($@) {
		skip "Can't create exec-only test tree: $@", 1;
	}
	if (-r $testdir) {
		skip "Unix permissions don't seem to work on your system.", 1;
	}
	eval {
		my %hash;
		tie %hash, 'Tie::StorableDir', dirname => $testdir;
		my @x = keys %hash;
	};
	my $ok = $@ && $@ =~ /Cannot open directory for read:/;
	ok($ok, 'Directory open failures');
}

SKIP: {
	my %hash;
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath($testdir, 0, 0700);
	};
	if ($@) {
		skip "Can't create test tree: $@", 2;
	}
	eval {
		tie %hash, 'Tie::StorableDir', dirname => $testdir;
		open FILE, ">$testdir/ktest"
			or skip "Can't create test file", 2;
		close FILE;
		chmod 0000, "$testdir/ktest"
			or skip "Can't chmod test file", 2;
        !-r "$testdir/ktest" && !-w "$testdir/ktest"
            or skip "Permissions aren't working properly, hmm", 2;
	};
	if ($@) {
		skip "Error: $@", 2;
	}
	eval {
		$hash{test} = 42;
	};
	ok($@ =~ /Error storing:/, 'Key write error');
	eval {
		my $x = $hash{test};
	};
	ok($@ =~ /Error retrieving:/, 'Key read error');
}

SKIP: {
	my %hash;
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath([$testdir, "$testdir/ktest"], 0, 0700);
	};
	if ($@) {
		skip "Can't create test tree: $@", 1;
	}
	tie %hash, 'Tie::StorableDir', dirname => $testdir;
	ok(keys %hash == 0, 'Directory ignoring');
}

SKIP: {
	my %hash;
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath([$testdir], 0, 0700);
		open FILE, ">$testdir/ktest2" or die $!;
		close FILE;
		chmod 0000, "$testdir/ktest2" or die $!;
		if (-r "$testdir/ktest2") {
			skip "Unix permissions don't seem to work on your system.", 1;
		}
	};
	if ($@) {
		skip "Can't create test tree: $@", 1;
	}
	tie %hash, 'Tie::StorableDir', dirname => $testdir;
	ok(keys %hash == 0, 'Unreadable file ignoring');
}


SKIP: {
	my %hash;
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath([$testdir], 0, 0700);
		open FILE, ">$testdir/foobar" or die $!;
		close FILE;
	};
	if ($@) {
		skip "Can't create test tree: $@", 1;
	}
	tie %hash, 'Tie::StorableDir', dirname => $testdir;
	ok(keys %hash == 0, 'Ill-formatted name ignoring');
}

SKIP: {
	my %hash;
	eval {
		File::Path::rmtree($testdir, 0, 0);
		File::Path::mkpath([$testdir, "$testdir/ktest"], 0, 0700);
	};
	skip "Can't create test tree: $@", 1 if $@;
	eval {
		tie %hash, 'Tie::StorableDir';
	};
	ok(!tied(%hash) && $@ =~ /Missing required parameter/, 'Require dirname');
	$SIG{__WARN__} = sub { die $_[0] };
	eval {
		tie %hash, 'Tie::StorableDir', dirname => $testdir, x => 42;
	};
	ok($@ =~ /One or more unrecognized/, 'Unrecognized options warning');
	untie %hash if tied %hash;
}
