
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/Types/Dist.pm',
    'lib/Types/OPM.pm',
    'lib/Types/RENEEB.pm',
    't/CpanfileTest.pm',
    't/CpanfileTest2.pm',
    't/base.t',
    't/cpanfile.t',
    't/cpanfile2.t',
    't/dist/fq.t',
    't/dist/name.t',
    't/dist/version.t',
    't/distname.t',
    't/distversion.t',
    't/opm/OPMFileTest.pm',
    't/opm/QuickMerge-3.3.2.opm',
    't/opm/opmfile.t',
    't/opm/version.opm',
    't/opm/version.t',
    't/opm/version_wildcard.t',
    't/otrsversion.t',
    't/otrsversionwildcard.t'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
