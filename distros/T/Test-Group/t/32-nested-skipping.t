#!perl -w

use strict;
use warnings;

=head1 NAME

32-nested-skipping.t - Skipping nested subtests

=cut

use Test::More tests => 7; # Sorry, no_plan not portable for Perl 5.6.1!
use Test::Group;
use lib "t/lib";
use testlib;

ok(my $perl = perl_cmd);
is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "nested skipping" # ...

use Test::More tests => 1;
use Test::Group;

test "outer test" => sub {
    begin_skipping_tests;
    test "skipped 1" => sub { die };
    test "skipped 2" => sub { die };
    test "skipped 3" => sub { die };
    end_skipping_tests;
};

EOSCRIPT
    # ...
    or warn $perl->stderr;


like(scalar($perl->stdout), qr/ok 1/);
unlike(scalar($perl->stdout), qr/skip/,
       "the *outer* test is a straight success");
unlike(scalar($perl->stdout), qr/ok 2/, "Sub-skipping doesn't fubar test count");

=pod

The same again, just for running under the debugger (it fails in a
surprising manner when it does fail so it's not as good a test for the
rest of the time)

=cut

my $result = tg_test_test "outer test" => sub {
    begin_skipping_tests;
    test "skipped 1" => sub { die };
    test "skipped 2" => sub { die };
    test "skipped 3" => sub { die };
    end_skipping_tests;
};

ok(! $result->is_failed, "test group successful");
ok($result->prints_OK);
