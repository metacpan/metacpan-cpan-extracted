use strict;
use warnings;
use FindBin;
use lib glob("$FindBin::Bin/extlib/*/lib");
use Test::More tests => 1;

require Test::UseAllModules;

my $has_warnings = 0;
{
  local $SIG{__WARN__} = sub { $has_warnings++ };
  Test::UseAllModules::_get_module_list();
}

ok !$has_warnings, "has no warnings";
