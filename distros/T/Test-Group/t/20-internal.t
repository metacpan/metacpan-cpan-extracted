use strict;
use warnings;

=head1 NAME

20-internal.t - Testing Test::Group using itself

=cut

use Test::More tests => 8; # Sorry, no_plan does not work with Perl
                           # 5.6.1's Test::Harness

use Test::Group;
use lib "t/lib";
use testlib;

ok(1, "non-wrapped tests still work");

test "success" => sub {
    ok(1);
};


my $status = tg_test_test "failure" => sub {
    ok(1);
    ok(1);
    ok(0);
    ok(1);
};

ok($status->is_failed, "failed test");

$status = tg_test_test "exception" => sub {
    die;
};
ok($status->is_failed, "exception causes failure");
ok(! $status->prints_OK);

$status = tg_test_test "empty (shall fail)" => sub { };
ok($status->is_failed, "empty test fails");

test "nested tests" => sub {
    pass;
    test "true" => sub { pass };
};

$status = tg_test_test "nested failed tests" => sub {
    test "true" => sub { pass };
    test "false" => sub { is("foo", "bar") };
    test "dies" => sub { die };
};
ok($status->is_failed);

1;
