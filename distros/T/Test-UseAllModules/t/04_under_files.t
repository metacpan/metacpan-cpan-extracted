use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::UseAllModules under => qw(lib t/lib/);
use Test::More tests => 2;

BEGIN {
  chdir 't/MANIFESTed';
  my @modules = Test::UseAllModules::_get_module_list();
  ok @modules == 3;
  ok( !grep {$_ =~ /^under/} @modules );
  chdir '../..';
}

