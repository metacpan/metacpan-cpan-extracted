# Test URI::Query revert()

use strict;
use vars q($count);

BEGIN { $count = 4 }
use Test::More tests => $count;

use_ok('URI::Query');

my $qq;

ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), "constructor ok");
my $str1 = $qq->stringify;

# Strip
$qq->strip(qw(foo fluffy));
my $str2 = $qq->stringify;
isnt($str1, $str2, "strings different after strip");

# Revert
$qq->revert;
my $str3 = $qq->stringify;
is($str1, $str3, "strings identical after revert");

