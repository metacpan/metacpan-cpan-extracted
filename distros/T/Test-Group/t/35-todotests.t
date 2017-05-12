#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

35-todotests.t - Testing correct handling of sub-TODO tests

=cut

use Test::More tests => 54; # Sorry, no_plan not portable for Perl 5.6.1!
use Test::Group;
use lib "t/lib";
use testlib;

use strict;
use warnings;


=head2 A florilege of TODO situations

=head3 Your ordinary failing TODO test

=cut

{
    my $result = do {
        local $TODO = "tout doux";
        tg_test_test "todo sub-test (expected failure)" => sub {
            fail;
        };
    };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
    like($result->prints_TODO_string, qr/tout doux/);
}

=pod

Putting "TODO" in the test name also works.

=cut

{
    my $result = tg_test_test "TODO in the test name" => sub {
        fail;
    };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
    like($result->prints_TODO_string, qr/in the test name/);

    # Also works for the empty test:
    $result = tg_test_test "TODO in the test name" => sub {
        fail;
    };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
    like($result->prints_TODO_string, qr/in the test name/);
};

=pod

The parser is not too stupid.

=cut

{
    my $result = tg_test_test "todo in lowercase doesn't count" => sub {
        pass;
    };
    ok(! $result->is_failed);
    ok(! $result->prints_TODO_string);

    $result = tg_test_test "MASTODON is not TO-DO" => sub { pass };
    ok(! $result->is_failed);
    ok(! defined $result->prints_TODO_string);
}

=head3 An unexpected success

=cut

{
    my $result = tg_test_test "todo sub-test (unexpected success)" => sub {
        pass;
        {
            local $TODO = "Aha, unexpected TODO success!";
            pass;
        }
    };
    ok($result->is_failed);
    ok($result->prints_OK);
    like($result->prints_TODO_string, qr/Aha/);
}

=head3 Mixing TODO and other test gizmos

=cut

{
    my $result = tg_test_test "mixed todo tests (overall success)" => sub {
        {
            local $TODO = "this needs work";
            fail;
        }
        {
            local $TODO = "this needs less work";
            pass;
        }
    };
    ok($result->is_failed);
    like($result->prints_TODO_string, qr/less work/);
    unlike($result->prints_TODO_string, qr/needs work/);
}

=pod

Failure trumps TODO success.

=cut

{
    my $result = tg_test_test "failure trumps todo success" => sub {
        fail;
        { local $TODO = "I'm feeling nauseous now..."; pass; }
    };
    ok($result->is_failed);
    ok(! $result->prints_OK);
    ok(! $result->prints_TODO_string);
}

=pod

TODO outside of a group even excuses an exception.

=cut

{
    my $result = do {
                  local $TODO = "a good excuse";
                  tg_test_test "ouch" => sub { die };
                 };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
    ok($result->prints_TODO_string);
}

=pod

On the other hand, TODO inside of a group doesn't.

=cut

{
    my $result = tg_test_test "argl" => sub {
                  local $TODO = "sorry, poor excuse";
                  die;
              };
    ok($result->is_failed);
    ok(! $result->prints_OK);
    ok(! $result->prints_TODO_string);
}


=pod

Skipping has no effect on TODO tests.

=cut

{
    my $result = do {
                  local $TODO = "unexpected success";
                  skip_next_test("just because I can");
                  tg_test_test "zoinx" => sub { pass };
                 };
    ok($result->is_skipped);
    ok(! $result->is_failed);
}

=head3 TODO and nested tests

=cut

{
    my $result = tg_test_test "todo and nested failure: outer test" => sub {
        local $TODO = "some excuse";
         test "todo and nested failure: inner test" => sub {
            pass;
            fail; # Overall failure
         };
    };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
}

{
    my $result = tg_test_test
      "todo and nested unexpected success: outer test" => sub {
        local $TODO = "unexpected success";
        test "todo and nested unexpected success: inner test" => sub {
           pass;
           pass;
        }
    };
    ok($result->is_failed);
    ok($result->prints_OK);
}
{
    my $result = tg_test_test "nested-todo failure: outer test" => sub {
        test "nested todo failure: inner test" => sub {
           local $TODO = "some excuse";
           fail;
        };
    };
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
}
{
    my $result = tg_test_test
      "nested-todo unexpected success: outer test" => sub {
        test "nested todo unexpected success: inner test" => sub {
           local $TODO = "unexpected success";
           fail;
           pass; # Semantics is different: "local $TODO" means that *all*
                 # sub-tests should fail.  Therefore the inner test
                 # is an unexpected TODO, and so is the outer one.
        };
    };
    ok($result->is_failed);
    ok($result->prints_OK);
}

=head2 POD snippet in L<Test::Group/Reflexivity>

=cut

{
    ok(my $perl = perl_cmd);
    my $code = get_pod_snippet("foobar_ok") . <<"TEST_CASE";
use Test::More tests => 10;
for(1..10) { foobar_ok("foobar") }
TEST_CASE
    is $perl->run(stdin => $code) >> 8, 0, "foobar_ok"
        or warn $perl->stderr;
    unlike(scalar($perl->stderr()), qr/not ok/, "success");
    unlike(scalar($perl->stderr()), qr/11/, "correct number of tests");
}

=head2 POD snippets in L<Test::Group/TODO Tests>

=cut

{
    my $code = get_pod_snippet("TODO gotcha");
    $code =~ s/test/tg_test_test/;
    my $result = eval($code); die $@ if $@;
    ok($result->is_failed);
    ok($result->prints_TODO_string);

    # The POD also states that the un-TODOified version of this test
    # is *also* borked:
    $code =~ s/TODO/TADA/g;
    $result = eval("use vars qw(\$TADA); $code"); die $@ if $@;
    ok($result->is_failed);
    ok(! defined $result->prints_TODO_string);
}

{
    my $code = get_pod_snippet("TODO correct");
    $code =~ s/test/tg_test_test/;
    my $result = eval($code); die $@ if $@;
    ok(! $result->is_failed);
    ok(! $result->prints_OK, "\"TODO correct\" prints_OK");
}

{
    my $code = get_pod_snippet("TODO gotcha 2");
    my $result = tg_test_test "testing TODO gotcha 2" =>
        sub { eval $code; die $@ if $@ };
    ok(! $result->got_exception);
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
}

=head2 POD snippet in L<Test::Group/SYNOPSIS>

This is a redux from C<30-synopsis.t>

=cut

{
    my $code = get_pod_snippet("synopsis-TODO");
    my $result = tg_test_test "testing synopsis-TODO" =>
        sub { eval $code; die $@ if $@ };
    ok(! $result->got_exception);
    ok(! $result->is_failed);
    ok(! $result->prints_OK);
}

