#! /usr/bin/env perl


use strict;
use warnings;
use Test::More;
use Test::Deep;

use Test::Mock::Test;

# ok
ok(0, "Test Ok being not ok or mocked ok");
Test::More::ok(0, "Test Ok being not ok or mocked ok");
ok(0);
Test::More::ok(0);

# is
is("a", "b", "Test Is being not ok or mocked ok");
Test::More::is("a", "b", "Test Is being not ok or mocked ok");
is("a", "b");
Test::More::is("a", "b");

# isnt
isnt("a", "a", "Test Isnt being not ok or mocked ok");
Test::More::isnt("a", "a", "Test Isnt being not ok or mocked ok");
isnt("a", "a");
Test::More::isnt("a", "a");

# like
like("a", qr/b/, "Test Like being not ok or mocked ok");
Test::More::like("a", qr/b/, "Test Like being not ok or mocked ok");
like("a", qr/b/);
Test::More::like("a", qr/b/);

# unlike
unlike("a", qr/a/, "Test Unlike being not ok or mocked ok");
Test::More::unlike("a", qr/a/, "Test Unlike being not ok or mocked ok");
unlike("a", qr/a/);
Test::More::unlike("a", qr/a/);

# misc
fail("I always fail");
can_ok("x", "y", "Yes we can!");
use_ok("hot::module");
require_ok("hot::module");
is_deeply({a => 'b'}, [1,2,3], "some deep test");
is_deeply({a => 'b'}, [1,2,3]);

# Test::Deep
cmp_bag([1, 2, 3, {a => "b" } ], [ 2, {a => "b" }, 3, 1 ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );
cmp_bag([1, 2, 3, {a => "b" } ], [ 2, {a => "c" }, 3, 1 ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

done_testing;
