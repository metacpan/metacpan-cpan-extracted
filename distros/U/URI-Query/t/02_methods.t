# URI::Query tests

use Test::More tests => 22;
BEGIN { use_ok( URI::Query ) }
use strict;
my $qq;

# Basics - scalar version
ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), "constructor ok");
is($qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 
  sprintf("stringifies ok (%s)", $qq->stringify));

# strip
ok($qq->strip(qw(foo bog)), "strip ok");
is($qq->stringify, 'bar=3&bar=7&fluffy=3', 
  sprintf("strip correct (%s)", $qq->stringify));

# Simple replace
$qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3');
ok($qq->replace(foo => 'xyz', bog => 'magic', extra => 1), "replace ok");
is($qq->stringify, 'bar=3&bar=7&bog=magic&extra=1&fluffy=3&foo=xyz', 
  sprintf("replace correct (%s)", $qq->stringify));

# Composite replace
ok($qq->replace(foo => [ 123, 456, 789 ], extra => 2), "replace ok");
is($qq->stringify, 'bar=3&bar=7&bog=magic&extra=2&fluffy=3&foo=123&foo=456&foo=789',
  sprintf("replace correct (%s)", $qq->stringify));

# Auto-stringification
is("$qq", 'bar=3&bar=7&bog=magic&extra=2&fluffy=3&foo=123&foo=456&foo=789',
  sprintf("auto-stringification ok (%s)", $qq . ''));

# strip_except
ok($qq->strip_except(qw(bar foo extra)), "strip_except ok");
is($qq->stringify, 'bar=3&bar=7&extra=2&foo=123&foo=456&foo=789',
  sprintf("strip_except correct (%s)", $qq->stringify));

# strip_null
ok($qq = URI::Query->new(foo => 1, foo => 2, bar => '', bog => 'abc', zero => 0, fluffy => undef), "array constructor ok");
ok($qq->strip_null, "strip_null ok");
is($qq->stringify, 'bog=abc&foo=1&foo=2&zero=0', 
  sprintf("strip_null correct (%s)", $qq->stringify));

# strip_like
ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3;zero=0'), "constructor ok");
ok($qq->strip_like(qr/^b/), "strip_like ok");
is($qq->stringify, 'fluffy=3&foo=1&foo=2&zero=0', 
  sprintf("strip_like correct (%s)", $qq->stringify));
ok($qq->strip_like(qr/^f[lzx]/), "strip_like ok");
is($qq->stringify, 'foo=1&foo=2&zero=0', 
  sprintf("strip_like correct (%s)", $qq->stringify));
ok($qq->strip_like(qr/\d/), "strip_like ok");
is($qq->stringify, 'foo=1&foo=2&zero=0', 
  sprintf("strip_like correct (%s)", $qq->stringify));

