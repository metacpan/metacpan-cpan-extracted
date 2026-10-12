use strict;
use warnings;

use Test::Tester;	# must be loaded before Test::Builder
use Test::Most;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::NoShadow qw(lib_ok);

ok(lib_ok('Test::NoShadow'), 'Test::NoShadow was loaded from this distribution');

subtest 'a shadowing copy is reported' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $dir = File::Spec->catdir($tmpdir, 'Test', 'NoShadow');
	make_path($dir);
	my $file = File::Spec->catfile($dir, 'Fake.pm');
	open(my $fh, '>', $file) or die "Cannot open $file: $!";
	print $fh "package Test::NoShadow::Fake;\n\nuse strict;\nuse warnings;\n\n1;\n";
	close($fh);
	unshift @INC, $tmpdir;
	require Test::NoShadow::Fake;

	my ($premature, @results) = run_tests(sub { lib_ok('Test::NoShadow::Fake') });

	is($results[0]{ok}, 0, 'fails when the module came from outside lib or blib/lib');

	my $diag = $results[0]{diag} || '';
	like($diag, qr/Test.NoShadow.Fake\.pm/, 'names the copy that was loaded');
};

subtest 'missing lib directories do not warn' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my ($premature, @results) = run_tests(sub {
		lib_ok('Test::NoShadow::Fake', { lib => [qw(no such lib)] });
	});

	is($results[0]{ok}, 0, 'still fails when the module is outside every lib');
	is(scalar(@warnings), 0, 'no warnings were emitted for lib directories that do not exist') or diag(@warnings);
};

subtest 'a module that was not loaded is reported' => sub {
	my ($premature, @results) = run_tests(sub { lib_ok('Test::NoShadow::NoSuchModule') });

	is($results[0]{ok}, 0, 'fails when the module is not in %INC');

	my $diag = $results[0]{diag} || '';
	like($diag, qr/has not been loaded/, 'says the module was not loaded');
};

subtest 'no modules given' => sub {
	my ($premature, @results) = run_tests(sub { lib_ok() });

	is($results[0]{ok}, 0, 'fails when given nothing to check');
};

done_testing();
