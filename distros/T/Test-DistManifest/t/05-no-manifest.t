# Test loading of a default MANIFEST.SKIP

use strict;
use warnings;

use Test::Builder::Tester tests => 1 + ($ENV{AUTHOR_TESTING} ? 1 : 0);
use Test::DistManifest;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use File::Spec;
use Cwd 'getcwd';

# If MANIFEST_WARN_ONLY is set, unset it
if (exists($ENV{MANIFEST_WARN_ONLY})) {
  delete($ENV{MANIFEST_WARN_ONLY});
}

my $old_wd = getcwd();
chdir 't/corpus/Bar';

# Test default MANIFEST.SKIP when none is present
#  1 test
test_out('ok 1 - Parse MANIFEST or equivalent');
test_diag('Unable to parse MANIFEST.SKIP file:');
test_diag('No such file or directory');
# this line no longer matches exactly, but we have skip_err => 1
test_diag('Using default skip data from ExtUtils::Manifest');
test_out('ok 2 - All files are listed in MANIFEST or skipped');
test_out('ok 3 - All files listed in MANIFEST exist on disk');
test_out('ok 4 - No files are in both MANIFEST and MANIFEST.SKIP');
manifest_ok('MANIFEST', 'INVALID.FILE');
test_test(
  name      => 'Uses default MANIFEST.SKIP on failure to parse',
  skip_err  => 1,
);
