use Test::More 'tests' => 8;
use lib '../lib';

use_ok('UDCode');
*is_prefix_of = \*UDCode::is_prefix_of;

ok(  is_prefix_of("", "abb"));
ok(  is_prefix_of("a", "abb"));
ok(  is_prefix_of("ab", "abb"));
ok(  is_prefix_of("abb", "abb"));
ok(! is_prefix_of("b", "abb"));
ok(! is_prefix_of("ba", "abb"));
ok(! is_prefix_of("bb", "abb"));


