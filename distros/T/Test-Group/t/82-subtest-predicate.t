#!perl -w

use strict;

=head1 NAME

82-subtest-predicate.t - defining new test predicates with Test::Group,
under use_subtest.

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

use Test::More tests => 16;
use Test::Group;
use lib "t/lib";
use testlib;

Test::Group->use_subtest;

my %line;

# foobar_ok; a predicate defined via Test::Group
sub foobar_ok {
    my ($text, $name) = @_;
    $name ||= "foobar_ok";
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test $name => sub {
       local $Test::Group::InPredicate = 1;
       ok $text =~ /foo/, "foo ok";
       ok $text =~ /bar/, "bar ok";  BEGIN{ $line{foobar_ok_bar} = __LINE__ }
    };
}

# foobar_ok_b: a predicate on top of foobar_ok, using the standard
# Test::Builder predicate-within-predicate mechanism.
sub foobar_ok_b {
    my ($thing, $name) = @_;
    $name ||= "foobar_ok_b";

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foobar_ok($thing, "$name");
}

# foobar_ok_bg: a Test::Group predicate on top of foobar_ok_b
sub foobar_ok_bg {
    my ($text, $name) = @_;
    $name ||= "foobar_ok_bg";
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test $name => sub {
        local $Test::Group::InPredicate = 1;
        ok "foo", "foo is true";
        foobar_ok_b($text, $name);
                           BEGIN{ $line{foobar_ok_bg_inner} = __LINE__-1 }
        ok "bar", "bar is true";
    };
}

# foobar_ok_bgb: another layer of predicate
sub foobar_ok_bgb {
    my ($thing, $name) = @_;
    $name ||= "foobar_ok_bgb";

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foobar_ok_bg($thing, $name);
}

# Try the predicates passing
foreach my $predicate (qw(foobar_ok foobar_ok_b)) {
    test_out(skip_any_comments());
    test_out("    ok 1 - foo ok");
    test_out("    ok 2 - bar ok");
    test_out("    1..2");
    test_out("ok 1 - $predicate");

    { no strict 'refs' ; &$predicate("foobar"); }

    test_test("$predicate passing");
}
foreach my $predicate (qw(foobar_ok_bg foobar_ok_bgb)) {
    test_out(skip_any_comments());
    test_out("    ok 1 - foo is true");
    test_out(skip_any_comments());
    test_out("        ok 1 - foo ok");
    test_out("        ok 2 - bar ok");
    test_out("        1..2");
    test_out("    ok 2 - $predicate");
    test_out("    ok 3 - bar is true");
    test_out("    1..3");
    test_out("ok 1 - $predicate");

    { no strict 'refs' ; &$predicate("foobar"); }

    test_test("$predicate passing");
}

# Try the predicates failing
foreach my $predicate (qw(foobar_ok foobar_ok_b)) {
    test_out(skip_any_comments());
    test_out("    ok 1 - foo ok");
    test_out("    not ok 2 - bar ok");
    test_err("    #   Failed test 'bar ok'");
    test_err("    #   at $0 line $line{foobar_ok_bar}.");
    test_out("    1..2");
    test_err("    # Looks like you failed 1 test of 2.");
    test_out("not ok 1 - $predicate");
    test_err("#   Failed test '$predicate'");
    test_err("#   at $0 line $line{outer1}.");

    {
        no strict 'refs';
        &$predicate("foobaz");  BEGIN{ $line{outer1} = __LINE__ }
    }

    test_test("$predicate failing");
}
foreach my $predicate (qw(foobar_ok_bg foobar_ok_bgb)) {
    test_out(skip_any_comments());
    test_out("    ok 1 - foo is true");
    test_out(skip_any_comments());
    test_out("        ok 1 - foo ok");
    test_out("        not ok 2 - bar ok");
    test_err("        #   Failed test 'bar ok'");
    test_err("        #   at $0 line $line{foobar_ok_bar}.");
    test_out("        1..2");
    test_err("        # Looks like you failed 1 test of 2.");
    test_out("    not ok 2 - $predicate");
    test_err("    #   Failed test '$predicate'");
    test_err("    #   at $0 line $line{foobar_ok_bg_inner}.");
    test_out("    ok 3 - bar is true");
    test_out("    1..3");
    test_err("    # Looks like you failed 1 test of 3.");
    test_out("not ok 1 - $predicate");
    test_err("#   Failed test '$predicate'");
    test_err("#   at $0 line $line{outer2}.");

    {
        no strict 'refs';
        &$predicate("foobaz");  BEGIN{ $line{outer2} = __LINE__ }
    }

    test_test("$predicate failing");
}

# Try the predicates passing in a group
foreach my $predicate (qw(foobar_ok foobar_ok_b)) {
    test_out(skip_any_comments());
    test_out(skip_any_comments());
    test_out("        ok 1 - foo ok");
    test_out("        ok 2 - bar ok");
    test_out("        1..2");
    test_out("    ok 1 - $predicate");
    test_out("    1..1");
    test_out("ok 1 - outergroup");

    test outergroup => sub {
        no strict 'refs';
        &$predicate("foobar");
    };

    test_test("$predicate passing in group");
}
foreach my $predicate (qw(foobar_ok_bg foobar_ok_bgb)) {
    test_out(skip_any_comments());
    test_out(skip_any_comments());
    test_out("        ok 1 - foo is true");
    test_out(skip_any_comments());
    test_out("            ok 1 - foo ok");
    test_out("            ok 2 - bar ok");
    test_out("            1..2");
    test_out("        ok 2 - $predicate");
    test_out("        ok 3 - bar is true");
    test_out("        1..3");
    test_out("    ok 1 - $predicate");
    test_out("    1..1");
    test_out("ok 1 - outergroup");

    test outergroup => sub {
        no strict 'refs';
        &$predicate("foobar");
    };

    test_test("$predicate passing in group");
}

# Try the predicates failing in a group
foreach my $predicate (qw(foobar_ok foobar_ok_b)) {
    test_out(skip_any_comments());
    test_out(skip_any_comments());
    test_out("        ok 1 - foo ok");
    test_out("        not ok 2 - bar ok");
    test_err("        #   Failed test 'bar ok'");
    test_err("        #   at $0 line $line{foobar_ok_bar}.");
    test_out("        1..2");
    test_err("        # Looks like you failed 1 test of 2.");
    test_out("    not ok 1 - $predicate");
    test_err("    #   Failed test '$predicate'");
    test_err("    #   at $0 line $line{inner1g}.");
    test_out("    1..1");
    test_err("    # Looks like you failed 1 test of 1.");
    test_out("not ok 1 - outergroup");
    test_err("#   Failed test 'outergroup'");
    test_err("#   at $0 line $line{outer1g}.");

    test outergroup => sub {
        no strict 'refs';
        &$predicate("foobaz");  BEGIN{ $line{inner1g} = __LINE__ }
    };                          BEGIN{ $line{outer1g} = __LINE__ }

    test_test("$predicate failing in group");
}
foreach my $predicate (qw(foobar_ok_bg foobar_ok_bgb)) {
    test_out(skip_any_comments());
    test_out(skip_any_comments());
    test_out("        ok 1 - foo is true");
    test_out(skip_any_comments());
    test_out("            ok 1 - foo ok");
    test_out("            not ok 2 - bar ok");
    test_err("            #   Failed test 'bar ok'");
    test_err("            #   at $0 line $line{foobar_ok_bar}.");
    test_out("            1..2");
    test_err("            # Looks like you failed 1 test of 2.");
    test_out("        not ok 2 - $predicate");
    test_err("        #   Failed test '$predicate'");
    test_err("        #   at $0 line $line{foobar_ok_bg_inner}.");
    test_out("        ok 3 - bar is true");
    test_out("        1..3");
    test_err("        # Looks like you failed 1 test of 3.");
    test_out("    not ok 1 - $predicate");
    test_err("    #   Failed test '$predicate'");
    test_err("    #   at $0 line $line{inner2g}.");
    test_out("    1..1");
    test_err("    # Looks like you failed 1 test of 1.");
    test_out("not ok 1 - outergroup");
    test_err("#   Failed test 'outergroup'");
    test_err("#   at $0 line $line{outer2g}.");

    test outergroup => sub {
        no strict 'refs';
        &$predicate("foobaz");  BEGIN{ $line{inner2g} = __LINE__ }
    };                          BEGIN{ $line{outer2g} = __LINE__ }

    test_test("$predicate failing in group");
}

