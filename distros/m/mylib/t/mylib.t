#!perl -w

use Test;
plan tests => 5;

use mylib qw($Prefix $Bin $Lib $Etc);
use Foo;

ok($Foo::VERSION);
ok($Prefix);
ok("$Prefix/lib", $Lib);
ok("$Prefix/etc", $Etc);
ok($Bin);
