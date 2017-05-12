use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::UseAllModules;

BEGIN {
  chdir 't/NoPM';
  all_uses_ok();
  chdir '../..';
}

