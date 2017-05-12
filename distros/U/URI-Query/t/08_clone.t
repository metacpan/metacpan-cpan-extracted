# Test URI::Query clone()

use strict;
use vars q($count);

use Test::More;

use_ok('URI::Query');

my $qq;

ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), "constructor ok");
my $str1 = $qq->stringify;
my $qstr = $qq->qstringify;
is($qstr, "?$str1", "qstringify ok: $qstr");

# Basic clone test
is($qq->clone->stringify, $str1, 'unchanged clone stringifies identically');

# Clone and make a change
isnt($qq->clone->strip('fluffy')->stringify, $qq->stringify, 'changed clone stringifies differently');

# Identical changes stringify identically
is($qq->clone->strip('fluffy')->qstringify, $qq->strip('fluffy')->qstringify, 'same changes qstringify identically');

done_testing;

