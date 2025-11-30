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
$ENV{PATH} = "$tempdir:$ENV{PATH}";

# Helper to create a mock executable
sub create_mock_program {
	my ($name, $script_content) = @_;

	my $path;
	if ($^O eq 'MSWin32') {
		# Create .bat file on Windows
		$path = File::Spec->catfile($tempdir, "$name.bat");
		open my $fh, '>', $path or die "Cannot create $path: $!";

		# Convert shell script to batch script
		my $batch_content = '@echo off' . "\n";

		# Simple conversion for basic cases
		if ($script_content =~ /echo "([^"]+)"/) {
			$batch_content .= "echo $1\n";
		}

		print $fh $batch_content;
		close $fh;
	} else {
		# Unix shell script
		$path = File::Spec->catfile($tempdir, $name);
		open my $fh, '>', $path or die "Cannot create $path: $!";
		print $fh $script_content;
		close $fh;
		chmod 0755, $path or die "Cannot chmod $path: $!";
	}

	return $path;
}

subtest 'edge cases and error conditions' => sub {

	# Program that outputs to STDERR only
	my $prog1 = create_mock_program('stderrprog', <<'EOF');
#!/bin/sh
if [ "$1" = "--version" ]; then
	echo "stderrprog 1.2.3" >&2
	exit 0
fi
exit 1
EOF

	use_ok('Test::Which', 'which_ok');

	ok(which_ok('stderrprog' => '>=1.0'), 'captures version from STDERR');

	# Program that exits with no output
	my $prog2 = create_mock_program('silentprog', <<'EOF');
#!/bin/sh
exit 0
EOF

	my $result = which_ok('silentprog', {
		version => '>=1.0',
		version_flag => '--version'
	});
	ok(!$result, 'handles programs with no output');

	# Program with year-based version format
	my $prog3 = create_mock_program('weirdver', <<'EOF');
#!/bin/sh
if [ "$1" = "-version" ]; then
	echo "Build 2020.10.15-git-abc123"
	exit 0
fi
exit 1
EOF

	ok(which_ok('weirdver', {
		version => '>=2020.10',
		version_flag => '-version'
	}), 'handles year-based version formats');

	# Test with regex
	ok(which_ok('weirdver', {
		version => qr/^2020\./,
		version_flag => '-version'
	}), 'handles version matching with regex');
};

done_testing();
