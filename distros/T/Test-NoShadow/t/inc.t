use strict;
use warnings;

use Test::Tester;	# must be loaded before Test::Builder
use Test::Most;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::NoShadow qw(shadowed_ok);

sub write_pm {
	my ($root, $package) = @_;

	my @parts = split(/::/, $package);
	# Build the directory with catdir, not splitpath: on Windows splitpath
	# returns the directory without the drive, so make_path would create
	# the tree on the wrong volume and the open below would fail
	my $dir = File::Spec->catdir($root, 'lib', @parts[0 .. $#parts - 1]);
	make_path($dir);
	my $file = File::Spec->catfile($dir, "$parts[-1].pm");
	open(my $fh, '>', $file) or die "Cannot open $file: $!";
	print $fh "package $package;\n\nuse strict;\nuse warnings;\n\n1;\n";
	close($fh);
}

subtest 'a single @INC entry is clean' => sub {
	my $root = tempdir(CLEANUP => 1);
	write_pm($root, 'Foo::Bar');

	my ($premature, @results) = run_tests(sub {
		local @INC = ($root);
		shadowed_ok();
	});

	is($results[0]{ok}, 1, 'shadowed_ok() with no arguments scans @INC and passes');
};

subtest 'the same package in two @INC entries is shadowed' => sub {
	my $root1 = tempdir(CLEANUP => 1);
	my $root2 = tempdir(CLEANUP => 1);
	write_pm($root1, 'Foo::Bar');
	write_pm($root2, 'Foo::Bar');

	my ($premature, @results) = run_tests(sub {
		local @INC = ($root1, $root2);
		shadowed_ok();
	});

	is($results[0]{ok}, 0, 'fails when two @INC entries provide the same package');

	my $diag = $results[0]{diag} || '';
	like($diag, qr/Foo::Bar is provided by 2 files:/, 'names the package');
	like($diag, qr/Foo.Bar\.pm/, 'names the files');
};

done_testing();
