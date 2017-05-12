#!perl -w

use strict;

use Test::More tests => 5;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;
use Test::LongString;

my $DEFAULT_FLAGS = $] < 5.013005 ? '-xism' : '^';

test_out("ok 1 - foo matches foo");
like_string("foo", qr/foo/, "foo matches foo");
test_test("a small string matches");

test_out("not ok 1 - foo matches foo");
test_fail(4);
test_diag(qq(         got: "bar"
#       length: 3
#     doesn't match '(?$DEFAULT_FLAGS:foo)'));
like_string("bar", qr/foo/, "foo matches foo");
test_test("a small string doesn't match");

test_out("not ok 1 - foo matches foo");
test_fail(4);
test_diag(qq(         got: undef
#       length: -
#     doesn't match '(?$DEFAULT_FLAGS:foo)'));
like_string(undef, qr/foo/, "foo matches foo");
test_test("got undef");

test_out("not ok 1 - long string matches a*");
test_fail(4);
test_diag(qq(         got: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"...
#       length: 100
#     doesn't match '(?$DEFAULT_FLAGS:^a*\$)'));
like_string(("a"x60)."b".("a"x39), qr/^a*$/, "long string matches a*");
test_test("a huge string doesn't match");

test_out("not ok 1 - foo doesn't match bar");
test_fail(4);
test_diag(qq(         got: "bar"
#       length: 3
#           matches '(?$DEFAULT_FLAGS:bar)'));
unlike_string("bar", qr/bar/, "foo doesn't match bar");
test_test("a small string matches while it shouldn't");
