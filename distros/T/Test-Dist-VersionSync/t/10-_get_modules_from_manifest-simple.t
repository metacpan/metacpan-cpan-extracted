#!perl -T

use strict;
use warnings;

use Test::Dist::VersionSync;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 10;


use_ok( 'Cwd' );

# Get untainted root directory.
my ( $root_directory ) = Cwd::getcwd() =~ /^(.*?)$/;

# Test retrieving modules from MANIFEST.
ok(
	chdir( 't/10-_get_modules_from_manifest-simple' ),
	'Change directory to t/10-_get_modules_from_manifest-simple.',
);

ok(
	-e 'MANIFEST',
	'MANIFEST file exists.',
);

ok(
	! -e 'MANIFEST.SKIP',
	'MANIFEST.SKIP file does not exist.',
);

my $modules = Test::Dist::VersionSync::_get_modules_from_manifest();
isa_ok(
	$modules,
	'ARRAY',
);

is_deeply(
	$modules,
	[
		'Test::Dist::VersionSync',
		'Test::Dist::VersionSync::Sample',
	],
	'Verify the list of modules found in MANIFEST.',
);

ok(
	chdir( $root_directory ),
	'Change back to the original directory.',
);
