use strict;
use warnings;

use Test::More;
use Test::Builder::Tester tests => 1;

use Test::NameNote;

test_out(
  "ok 1 - foo true",
  "ok 2 - thing returns thing (foo=0,bar=0)",
  "ok 3 - thang returns thang (foo=0,bar=0)",
  "ok 4 - thing returns thing (foo=0,bar=1)",
  "ok 5 - thang returns thang (foo=0,bar=1)",
  "ok 6 - thing returns thing (foo=1,bar=0)",
  "ok 7 - thang returns thang (foo=1,bar=0)",
  "ok 8 - thing returns thing (foo=1,bar=1)",
  "ok 9 - thang returns thang (foo=1,bar=1)",
  "ok 10 - bar true",
);

ok foo(), "foo true";
foreach my $foo (0, 1) {
    my $n1 = Test::NameNote->new("foo=$foo");
    foreach my $bar (0, 1) {
        my $n2 = Test::NameNote->new("bar=$bar");
        is thing($foo, $bar), "thing", "thing returns thing";
        is thang($foo, $bar), "thang", "thang returns thang";
    }
}
ok bar(), "bar true";

test_test();

sub foo { 1 }
sub bar { 1 }
sub thing { "thing" }
sub thang { "thang" }

