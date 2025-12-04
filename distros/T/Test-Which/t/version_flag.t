#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use File::Which qw(which);

BEGIN {
	# FIXME
	if ($^O eq 'MSWin32') {
		plan skip_all => 'Shell script mock programs not compatible with Windows';
	}
}

my $tempdir = tempdir(CLEANUP => 1);
my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
$ENV{PATH} = "$tempdir$path_sep$ENV{PATH}";

# ------------------------------------------------------------------
# Create a mock program that behaves the same on Windows and Unix
# ------------------------------------------------------------------
sub create_mock_program {
	my ($name, $version, $flag) = @_;
	$flag ||= '--version';

	my $path;

	if ($^O eq 'MSWin32') {
		# Windows batch file
		$path = File::Spec->catfile($tempdir, "$name.bat");

		open my $fh, '>', $path or die "Cannot create $path: $!";

		print $fh '@echo off', "\r\n";

		# Accept either a single flag or multiple possible flags
		print $fh "set FLAG=%~1\r\n";
		print $fh "if \"%FLAG%\"==\"$flag\" goto showver\r\n";
		print $fh "exit /b 1\r\n";

		print $fh ":showver\r\n";
		print $fh "echo $name version $version\r\n";
		print $fh "exit /b 0\r\n";

		close $fh;
	} else {
		# Unix shell script
		$path = File::Spec->catfile($tempdir, $name);
		open my $fh, '>', $path or die "Cannot create $path: $!";
		print $fh "#!/bin/sh\n";
		print $fh "if [ \"\$1\" = \"$flag\" ]; then\n";
		print $fh "  echo \"$name version $version\"\n";
		print $fh "  exit 0\n";
		print $fh "fi\n";
		print $fh "exit 1\n";
		close $fh;
		chmod 0755, $path or die "Cannot chmod $path: $!";
	}

	return $path;
}

# ------------------------------------------------------------------
# Subtests
# ------------------------------------------------------------------

subtest 'verify basic functionality first' => sub {
	create_mock_program('basicprog', '1.2.3');

	use_ok('Test::Which', 'which_ok');

	my $result = which_ok('basicprog' => '>=1.0');
	ok($result, 'basic string constraint works');

	my $prog_name = $^O eq 'MSWin32' ? 'basicprog.bat' : 'basicprog';
	my $path = which($prog_name);

	ok($path, "basicprog located: " . ($path // 'undef'));

	SKIP: {
		skip 'Program not found', 2 unless $path;

		require Test::Which;

		my $output = Test::Which::_capture_version_output($path, '--version');
		ok(defined $output, "Got version output");

		my $version = Test::Which::_extract_version($output);
		is($version, '1.2.3', "Extracted correct version");
	}
};

subtest 'test hashref constraint support' => sub {
	create_mock_program('hashprog', '2.5.1');

	use_ok('Test::Which', 'which_ok');

	my $result;
	lives_ok {
		$result = which_ok('hashprog', { version => '>=2.0' });
	} 'hashref constraint accepted';

	ok($result, 'hashref version >=2.0 works');
};

subtest 'custom version flag - string constraint only' => sub {
	create_mock_program('customprog', '3.0.0', '-show-ver');

	use_ok('Test::Which', 'which_ok');

	# Should fail with default flags
	my $result1 = which_ok('customprog' => '>=3.0');
	ok(!$result1, 'Fails with default flags');

	# Should succeed with custom flag
	my $result2;
	lives_ok {
		$result2 = which_ok('customprog', {
			version => '>=3.0',
			version_flag => '-show-ver'
		});
	};

	ok($result2, 'Succeeds using custom version_flag');
};

subtest 'test _capture_version_output with custom flag' => sub {
	create_mock_program('flagprog', '1.5.0', '-show-ver');

	use_ok('Test::Which');

	my $prog_name = $^O eq 'MSWin32' ? 'flagprog.bat' : 'flagprog';
	my $path = which($prog_name);

	ok($path, 'flagprog found');

	SKIP: {
		skip 'Program missing', 2 unless $path;

		my $output;
		lives_ok {
			$output = Test::Which::_capture_version_output($path, '-show-ver');
		} '_capture_version_output runs';

		like($output || '', qr/1\.5\.0/, 'Output contains version');
	}
};

subtest 'test array of version flags' => sub {
	create_mock_program('arrayprog', '2.0.0', '-ver');

	use_ok('Test::Which', 'which_ok');

	my $result;
	lives_ok {
		$result = which_ok('arrayprog', {
			version => '>=2.0',
			version_flag => ['--version', '-ver']
		});
	} 'array version_flag accepted';

	ok($result, 'array of version flags works');
};

subtest 'test regex constraint' => sub {
	create_mock_program('regexprog', '5.10.1');

	use_ok('Test::Which', 'which_ok');

	my $result;
	lives_ok {
		$result = which_ok('regexprog', {
			version => qr/^5\.\d+/
		});
	} 'regex constraint accepted';

	ok($result, 'regex constraint works');
};

subtest 'test empty version flag' => sub {
	SKIP: {
		skip 'Empty flag not supported on Windows', 3 if $^O eq 'MSWin32';

		my $prog = File::Spec->catfile($tempdir, 'noflagprog');
		open my $fh, '>', $prog or die $!;
		print $fh "#!/bin/sh\n";
		print $fh "if [ \$# -eq 0 ]; then\n";
		print $fh "  echo \"noflagprog 1.0.0\"\n";
		print $fh "  exit 0\n";
		print $fh "fi\n";
		print $fh "exit 1\n";
		close $fh;
		chmod 0755, $prog;

		use_ok('Test::Which', 'which_ok');

		my $result;
		lives_ok {
			$result = which_ok('noflagprog', {
				version => '>=1.0',
				version_flag => ''
			});
		};

		ok($result, 'empty version flag accepted');
	}
};

done_testing();
