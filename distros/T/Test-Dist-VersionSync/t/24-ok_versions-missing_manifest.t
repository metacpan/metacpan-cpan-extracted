#!perl -T

use strict;
use warnings;

use Test::Builder::Tester;
use Test::Dist::VersionSync;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


use_ok( 'Cwd' );

# Get untainted root directory.
my ( $root_directory ) = Cwd::getcwd() =~ /^(.*?)$/;

ok(
	chdir( 't/24-ok_versions-missing_manifest' ),
	'Change directory to 24-ok_versions-missing_manifest.',
);

ok(
	unshift( @INC, 'lib/' ),
	'Add the test lib/ directory to @INC.',
);

test_out( '1..5')
	if $Test::More::VERSION >= 1.005000005 && $Test::More::VERSION < 1.300;;
test_out( 'ok 1 - No MANIFEST.SKIP found, skipping.' );
test_out( 'not ok 2 - The MANIFEST file is present at the root of the distribution.' );
test_out( 'ok 3 # skip MANIFEST is missing, cannot retrieve list of files.' );
test_out( 'ok 4 # skip No module found in the distribution.' );
test_out( 'ok 5 # skip No module found in the distribution.' );

Test::Dist::VersionSync::ok_versions();

test_test(
	name     => "ok_versions() fails nicely when MANIFEST is missing.",
	skip_err => 1,
);

ok(
	chdir( $root_directory ),
	'Change back to the original directory.',
);
