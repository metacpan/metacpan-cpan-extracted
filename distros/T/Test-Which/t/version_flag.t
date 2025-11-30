#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use File::Which qw(which);

my $tempdir = tempdir(CLEANUP => 1);
my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
$ENV{PATH} = "$tempdir$path_sep$ENV{PATH}";

sub create_mock_program {
	my ($name, $version, $flag) = @_;
	$flag ||= '--version';

	my $path;

	if ($^O eq 'MSWin32') {
		# Create Windows batch file
		$path = File::Spec->catfile($tempdir, "$name.bat");
		open my $fh, '>', $path or die "Cannot create $path: $!";
		print $fh '@echo off' . "\r\n";
		print $fh "if \"%1\"==\"$flag\" (\r\n";
		print $fh "  echo $name version $version\r\n";
		print $fh "  exit /b 0\r\n";
		print $fh ")\r\n";
		print $fh "exit /b 1\r\n";
		close $fh;
	} else {
		# Create Unix shell script
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

subtest 'verify basic functionality first' => sub {
	create_mock_program('basicprog', '1.2.3', '--version');

	use_ok('Test::Which', 'which_ok');

	# Test basic string constraint
	my $result = which_ok('basicprog' => '>=1.0');
	ok($result, 'basic string constraint works') or diag("Result: $result");

	# Test if program can be found
	my $prog_name = $^O eq 'MSWin32' ? 'basicprog.bat' : 'basicprog';
	my $path = which($prog_name);
	ok($path, "basicprog found at: " . ($path // 'undef'));

	SKIP: {
		skip 'Program not found', 2 unless $path;

		# Manually test version detection
		require Test::Which;
		my $output = Test::Which::_capture_version_output($path);
		ok(defined $output, "Got output: " . (defined $output ? $output : 'undef'));

		my $version = Test::Which::_extract_version($output);
		is($version, '1.2.3', "Extracted version correctly: " . (defined $version ? $version : 'undef'));
	}
};

subtest 'test hashref constraint support' => sub {
	create_mock_program('hashprog', '2.5.1', '--version');

	use_ok('Test::Which', 'which_ok');

	# Test if hashref is accepted at all
	my $result;
	lives_ok {
		$result = which_ok('hashprog', { version => '>=2.0' });
	} 'hashref constraint does not die';

	ok($result, 'hashref with string version works')
		or diag('Hashref constraint failed - may not be implemented yet');
};

subtest 'custom version flag - string constraint only' => sub {
	create_mock_program('customprog', '3.0.0', '-show-ver');	# Changed from '-v'

	use_ok('Test::Which', 'which_ok');

	# First verify it fails with default flags
	my $result1 = which_ok('customprog' => '>=3.0');
	ok(!$result1, 'fails with default flags (as expected)');

	# Now test with custom flag in hashref
	my $result2;
	lives_ok {
		$result2 = which_ok('customprog', {
			version => '>=3.0',
			version_flag => '-show-ver'  # Changed from '-v'
		});
	} 'custom version_flag does not die';

	ok($result2, 'succeeds with custom version_flag')
		or diag("Custom version_flag may not be implemented yet");
};

subtest 'test _capture_version_output with custom flag' => sub {
	create_mock_program('flagprog', '1.5.0', '-show-ver');

	use_ok('Test::Which');

	my $prog_name = $^O eq 'MSWin32' ? 'flagprog.bat' : 'flagprog';
	my $path = which($prog_name);
	ok($path, "flagprog found");

	SKIP: {
		skip 'Program not found', 2 unless $path;

		# Test with custom flag
		my $output2;
		lives_ok {
			$output2 = Test::Which::_capture_version_output($path, '-show-ver');
		} '_capture_version_output accepts second parameter';

		like($output2 || '', qr/1\.5\.0/, 'custom flag returns version')
			or diag("Output with custom flag: " . ($output2 // 'undef'));
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
	} 'array of version_flags does not die';

	ok($result, 'array of flags works')
		or diag('Array version_flag may not be implemented yet');
};

subtest 'test regex constraint' => sub {
	create_mock_program('regexprog', '5.10.1', '--version');

	use_ok('Test::Which', 'which_ok');

	my $result;
	lives_ok {
		$result = which_ok('regexprog', {
			version => qr/^5\.\d+/
		});
	} 'regex constraint does not die';

	ok($result, 'regex constraint works')
		or diag('Regex constraint may not be implemented yet');
};

subtest 'test empty version flag' => sub {
	SKIP: {
		skip 'Empty flag test not supported on Windows', 3 if $^O eq 'MSWin32';

		# This requires more complex shell scripting
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
		} 'empty version_flag does not die';

		ok($result, 'empty string flag works')
			or diag('Empty version_flag may not be implemented yet');
	}
};

subtest 'summary of implementation status' => sub {
	note('This test summarizes what features are working');
	pass('Check earlier subtests for implementation status');
};

done_testing();
