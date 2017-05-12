# Ensures MANIFEST file is up-to-date

use strict;
use warnings;

use Test::More;
use Test::DistManifest;

plan skip_all => 'this test only works in a fully-built repository'
    if -d '.git' || !-f 'META.yml' || !-f 'MANIFEST';

my $min_eum =
    -d '_eumm' ? '1.70'                     # EUMM 7.05_07 generates _eumm/
  : -f '_build_params' ? '1.69'             # MBT 0.006 generates _build_params
  : -f 'MYMETA.yml' ? '1.58'                # EUMM 6.57_07, MBT 0.005 generates MYMETA*
  : $^O eq 'VMS' ? '1.57'                   # EUM skips VMS make artifacts
  : '0';

plan skip_all => 'ExtUtils::Manifest not new enough - your configuration requires version ' . $min_eum
    if not eval { ExtUtils::Manifest->VERSION($min_eum); 1 };


# since we have no MANIFEST.SKIP in the repo, a default one is used.
manifest_ok();
