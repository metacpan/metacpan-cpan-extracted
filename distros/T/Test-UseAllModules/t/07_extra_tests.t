use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::More;
use Test::UseAllModules under => qw(lib t/lib/);

BEGIN {
  chdir 't/MANIFESTed';

  plan tests => Test::UseAllModules::_get_module_list() + 1;

  all_uses_ok();
  chdir '../..';

  pass "test count should be correct";
}

