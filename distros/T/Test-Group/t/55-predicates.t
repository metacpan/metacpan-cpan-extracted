use strict;
use warnings;

=head1 NAME

55-predicates.t - defining new test predicates with Test::Group

=cut

use Test::More tests => 1;
use Test::Group::Tester;
use Test::Group;
use lib "t/lib";
use testlib;

my $scriptline = __LINE__ ; my $script = <<'EOSCRIPT';
use strict;
use warnings;

use Test::Builder;
use Test::Group;
use Test::More;

__FOOBAR_OK__

# foobar_ok_b: a predicate on top of foobar_ok, using the standard
# Test::Builder predicate-within-predicate mechanism.
sub foobar_ok_b {
    my ($thing, $name) = @_;

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
        ok "bar", "bar is true";
    };
}

# foobar_ok_bgb: another layer of predicate
sub foobar_ok_bgb {
    my ($thing, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foobar_ok_bg($thing, $name);
}


foreach my $pred (qw(foobar_ok foobar_ok_b foobar_ok_bg foobar_ok_bgb)) {
    # Try the predicate passing
    want_test('pass', "pass $pred");
    { no strict 'refs' ; &$pred("foobar", "pass $pred") };

    # Try the predicate failing
    want_test('fail', "fail $pred", 
        fail_diag("bar ok"),
        qr/^#\s*'foobaz'$/,
        qr/\bdoesn't match\b/,
          # An extra layer of Test::Group means an extra fail diag:
          ( $pred =~ /_bg/ ? fail_diag("fail $pred") : () ),
        fail_diag("fail $pred", 1, __LINE__+2),
    );
    { no strict 'refs' ; &$pred("foobaz", "fail $pred") };

    # Passing in a group
    want_test('pass', "pass group$pred");
    test "pass group$pred" => sub {
        no strict 'refs' ; &$pred("foobar", "pass $pred");
    };

    # Failing in a group
    want_test('fail', "fail group$pred", 
        fail_diag("bar ok"),
        qr/^#\s*'foobaz'$/,
        qr/\bdoesn't match\b/,
          # An extra layer of Test::Group means an extra fail diag:
          ( $pred =~ /_bg/ ? fail_diag("fail $pred") : () ),
        fail_diag("fail $pred", 0, __LINE__+4),
        fail_diag("fail group$pred", 1, __LINE__+4),
    );
    test "fail group$pred" => sub {
        no strict 'refs' ; &$pred("foobaz", "fail $pred");
    };
}


EOSCRIPT

my $foobar_ok = get_pod_snippet("foobar_ok");
my $hashline = "#line ".($scriptline+8)."\n";
$script =~ s/__FOOBAR_OK__/$foobar_ok\n$hashline/;

testscript_ok($script, 16);

