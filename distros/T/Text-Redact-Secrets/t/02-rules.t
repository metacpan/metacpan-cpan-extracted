use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The module of rules, as scripts/update-rules writes it: where its rules
# came from, and that each is whole and compiles as the module compiles
# it; and the module's own rules, beside them. What each finds is tested
# with the scan.

use Text::Redact::Secrets::Rules::Dist;
use Text::Redact::Secrets::Rules::Gitleaks;

my $rules   = Text::Redact::Secrets::Rules::Gitleaks::rules();
my $globals = Text::Redact::Secrets::Rules::Gitleaks::global_allowlists();

# The prefix gitleaks' generator begins some rules with, which D13
# merges into one repeat.
my $DOUBLED = q{[\w.-]{0,50}?(?i:[\w.-]{0,50}?};

# Each regex, compiled as the module compiles it: with /a, and quiet
# about a literal {, which Go's RE2 reads as Perl does, but which Perl
# warns of.
sub compiles ($regex) {
    no warnings qw(regexp);
    return eval { qr($regex)a; 1 };
}

subtest 'Where the rules came from' => sub {
    like Text::Redact::Secrets::Rules::Gitleaks::gitleaks_tag(),
        qr( \A v \d+ \. \d+ \. \d+ \z )x, 'a gitleaks tag';
    like Text::Redact::Secrets::Rules::Gitleaks::gitleaks_commit(),
        qr( \A [0-9a-f]{40} \z )x, 'a full commit hash';
};

subtest 'The rules' => sub {
    ok @$rules > 0, 'there are some';
    my %ids;
    for my $rule (@$rules) {
        my $id = $rule->{id} // '(no id)';
        $ids{$id}++;
        ok defined $rule->{regex},   "$id has a regex";
        ok compiles($rule->{regex}), "${id}'s regex compiles";
        isnt substr($rule->{regex}, 0, length $DOUBLED), $DOUBLED,
            "${id}'s regex doesn't begin with the doubled repeat D13 merges";
        for my $allowlist (@{ $rule->{allowlists} // [] }) {
            ok compiles($_), "${id}'s allowlist's regex compiles: $_"
                for @{ $allowlist->{regexes} // [] };
        }
    }
    is [grep { $ids{$_} > 1 } sort keys %ids], [], 'each id is used once';
};

subtest 'The global allowlists' => sub {
    ok @$globals > 0, 'there are some';
    for my $allowlist (@$globals) {
        ok $allowlist->{regexes} || $allowlist->{stopwords},
            'each has regexes or stopwords';
        ok compiles($_), "its regex compiles: $_"
            for @{ $allowlist->{regexes} // [] };
    }
};

subtest "The module's own rules" => sub {
    my %gitleaks = map { $_->{id} => 1 } @$rules;
    for my $rule (@{ Text::Redact::Secrets::Rules::Dist::rules() }) {
        ok !$gitleaks{$rule->{id}},  "$rule->{id} isn't one of gitleaks' ids";
        ok compiles($rule->{regex}), "$rule->{id}'s regex compiles";
    }
};

done_testing;
