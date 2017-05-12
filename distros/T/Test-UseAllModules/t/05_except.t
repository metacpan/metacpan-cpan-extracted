use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::UseAllModules;
use Test::More tests => 2;

BEGIN {
  chdir 't/MANIFESTed';
  my @modules = Test::UseAllModules::_get_module_list( except => qr/Foo/ );
  ok @modules == 1;
  ok $modules[0] eq 'TestUseAllModulesTest';
  chdir '../..';
}

