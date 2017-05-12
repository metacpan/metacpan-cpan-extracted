#!perl -w

use strict;

=head1 NAME

81-subtest-output.t - check that test output is as expected when
use_subtest has been set.

=cut

use Test::Builder;

BEGIN {
    my $T = Test::Builder->new;
    unless ($T->can('subtest')) {
        $T->skip_all('Test::Builder too old');
    }
    eval 'use Test::Builder::Tester';
    $T->skip_all('Test::Builder::Tester required') if $@;
}

use Test::More tests => 3;
use Test::Group;
use lib "t/lib";
use testlib;

Test::Group->use_subtest;

{
    test_out(skip_any_comments());
    test_out("    ok 1 - phew");
    test_out("    1..1");
    test_out("ok 1 - this passes");

    test "this passes" => sub {
        ok(1, "phew");
    };

    test_test("single passing test in group");
}
{
    my %line;

    test_out(skip_any_comments());
    test_out("    not ok 1 - oops");
    test_err("    #   Failed test 'oops'");
    test_err("    #   at $0 line $line{inner}.");
    test_out("    1..1");
    test_err("    # Looks like you failed 1 test of 1.");
    test_out("not ok 1 - this fails");
    test_err("#   Failed test 'this fails'");
    test_err("#   at $0 line $line{outer}.");

    test "this fails" => sub {
        ok(0, "oops");              BEGIN{ $line{inner} = __LINE__ }
    };                              BEGIN{ $line{outer} = __LINE__ }

    test_test("single failing test in group");
}
{
    my %line;

    test_out(skip_any_comments());
    test_out("    not ok 1 - oops");
    test_err("    #   Failed test 'oops'");
    test_err("    #   at $0 line $line{inner}.");
    test_out("    ok 2 - phew");
    test_out("    1..2");
    test_err("    # Looks like you failed 1 test of 2.");
    test_out("not ok 1 - this fails");
    test_err("#   Failed test 'this fails'");
    test_err("#   at $0 line $line{outer}.");

    test "this fails" => sub {
        ok(0, "oops");              BEGIN{ $line{inner} = __LINE__ }
        ok(1, "phew");
    };                              BEGIN{ $line{outer} = __LINE__ }

    test_test("1 fail and 1 pass in group");
}

