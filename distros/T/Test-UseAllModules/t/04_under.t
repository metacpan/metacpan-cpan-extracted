use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::UseAllModules under => qw(lib t/lib/);

BEGIN {
  chdir 't/MANIFESTed';
  all_uses_ok();
  chdir '../..';
}

