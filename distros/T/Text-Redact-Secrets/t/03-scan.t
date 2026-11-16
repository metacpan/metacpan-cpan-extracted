use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# How the scan runs rules, as gitleaks' detector does, shown with rules
# made up here, so that no secret is needed: keywords first, the secret
# picked out of the match, entropy, allowlists, gitleaks:allow, and the
# findings of a generic rule dropped. gitleaks' own rules are tested in
# t/gitleaks-false-positives.t and by hand.

use Text::Redact::Secrets;

# Return what the scan finds in the text by the rules, each as
# [rule, secret, offset].
sub found ($text, $rules, $globals = []) {
    my $compiled = Text::Redact::Secrets::_compile($rules, $globals);
    return [map { [$_->{rule}, $_->{secret}, $_->{offset}] }
        Text::Redact::Secrets::_scan($text, $compiled)];
}


# Return the text redacted by the rules.
sub redacted ($text, $rules) {
    return Text::Redact::Secrets::_redact(
        $text,
        Text::Redact::Secrets::_compile($rules, []),
    );
}

subtest 'Keywords: a rule runs only if one of its keywords is in the text' =>
    sub {
        my $rule = {id => 'kw', regex => 'tok-\w+', keywords => ['ZZ']};
        is found('tok-abc', [$rule]), [], 'none of them';
        is found('zz tok-abc', [$rule]), [['kw', 'tok-abc', 3]],
        'one, matched whatever its case';
        is found('tok-abc', [{id => 'all', regex => 'tok-\w+'}]),
        [['all', 'tok-abc', 0]], 'a rule with none always runs';
        is found('tok-abc', [{id => 'empty', regex => 'tok-\w+', keywords => []}]),
        [['empty', 'tok-abc', 0]], 'as does one whose list of them is empty';
        is found(
            'sk-ant-1', [
                {id => 'short', regex => 'sk-ant', keywords => ['sk']},
                {id => 'long',  regex => 'ant-1',  keywords => ['sk-ant']},
            ],
        ),
        [['short', 'sk-ant', 0], ['long', 'ant-1', 3]],
        'one that starts where a longer one does';
        is found(
            'abcd', [
                {id => 'left',  regex => 'ab', keywords => ['abc']},
                {id => 'right', regex => 'cd', keywords => ['bcd']},
            ],
        ),
        [['left', 'ab', 0], ['right', 'cd', 2]], 'and two that overlap';
    };

subtest 'The secret: as gitleaks picks it out of the match (D8)' => sub {
    is found('a-bb', [{id => 'g', regex => '(a)-(b+)', secret_group => 2}]),
        [['g', 'bb', 2]], 'the group the rule names';
    is found('a-bb', [{id => 'g', regex => '(a)-(b+)', secret_group => 3}]),
        [], 'none if the rule names a group its regex lacks';
    is found('y', [{id => 'g', regex => '(x)?(y)', secret_group => 1}]),
        [['g', '', 0]], 'empty if the group it names matched nothing';
    is found('-cc', [{id => 'g', regex => '(x?)-(c+)'}]),
        [['g', 'cc', 1]], 'else the first group that isn\'t empty';
    is found('-', [{id => 'g', regex => '(x?)-(y?)'}]),
        [['g', '-', 0]], 'else, if every group is empty, the whole match';
    is found('k-vv', [{id => 'g', regex => 'k-v+'}]),
        [['g', 'k-vv', 0]], 'and the whole match if there are no groups';
    is found('kvv', [{id => 'g', regex => '(?<=k)(v+)'}]),
        [['g', 'vv', 1]],
        'or if the regex, run again on the match alone, doesn\'t match';
    is found("a\ntok\nb", [{id => 'n', regex => '\ntok\n'}]),
        [['n', 'tok', 2]], 'newlines are trimmed from the match';
};

subtest 'Entropy: a secret must have more than the rule asks (D5)' => sub {
    my $rule = {id => 'e', regex => 'v=(\w*)', entropy => 1};
    is found('v=aaaa', [$rule]), [],                 'none';
    is found('v=aabb', [$rule]), [],                 'as much';
    is found('v=abcd', [$rule]), [['e', 'abcd', 2]], 'more';
    is found(
        'y',
        [{id => 'e', regex => '(x)?(y)', secret_group => 1, entropy => 1}],
        ),
        [], 'an empty secret has none';
    is Text::Redact::Secrets::_entropy('abcdefgh'), 3, 'counted in bits';
};

subtest 'Allowlists: what passes over a finding (D7)' => sub {
    my $rule = sub (%allowlist) {
        return {id => 'a', regex => 'k=(\w+)', allowlists => [\%allowlist]};
    };
    is found('k=ok1', [$rule->(regexes => ['ok'])]), [],
        'a regex matching the secret';
    is found('k=ok1', [$rule->(regexes => ['k='])]), [['a', 'ok1', 2]],
        'which is matched against the secret by default';
    is found('k=ok1', [$rule->(regexes => ['k='], regex_target => 'match')]),
        [], 'or the match';
    is found(
        "x k=ok1 y\nz",
        [$rule->(regexes => ['x .* y'], regex_target => 'line')],
        ),
        [], 'or the line';
    is found('k=OK1', [$rule->(stopwords => ['ok'])]), [],
        'a stopword in the secret, lowercased';
    is found('k=ok1', [$rule->(regexes => ['ok'], stopwords => ['no'])]),
        [], 'either, by default';
    is found(
        'k=ok1',
        [$rule->(regexes => ['ok'], stopwords => ['no'], condition => 'AND')],
        ),
        [['a', 'ok1', 2]], 'but both, under AND';
    is found(
        'k=ok1',
        [$rule->(regexes => ['ok'], stopwords => ['ok'], condition => 'AND')],
        ),
        [], 'which passes over it if both do';
    is found('k=ok1', [$rule->(regexes => ['ok'], condition => 'AND')]),
        [], 'or the one it has';
    is found('k=ok1', [$rule->(stopwords => ['ok'], condition => 'AND')]),
        [], 'whichever it is';
    is found(
        'k=ok1', [{id => 'a', regex => 'k=(\w+)'}],
        [{regexes => ['ok']}],
        ),
        [], 'and the global allowlists apply to every rule';
    is found(
        'y',
        [{
            id           => 'g',
            regex        => '(x)?(y)',
            secret_group => 1,
            allowlists   => [{regexes => ['.*'], stopwords => ['y']}],
        }],
        ),
        [['g', '', 0]], 'but nothing passes over an empty secret';
};

subtest 'gitleaks:allow passes over what\'s on its line' => sub {
    my $rule = {id => 'x', regex => 'k=\w+'};
    is found('k=1 # gitleaks:allow', [$rule]), [], 'on the same line';
    is found("k=1\n# gitleaks:allow", [$rule]), [['x', 'k=1', 0]],
        'not on another';
};

subtest 'The line, as gitleaks finds it' => sub {
    my $line = \&Text::Redact::Secrets::_line;
    is $line->('abc', 1, 2), 'abc', 'with no newline, the whole text';
    is $line->("ab\ncd\nef", 3, 4), "\ncd",
        'from the newline before the match to the one after';
    is $line->("ab\ncd\nef",  0, 1), 'ab',     'the first line';
    is $line->("ab\ncd\nef",  1, 4), "ab\ncd", 'a match across lines';
    is $line->("ab\ncd\r\nx", 7, 8), "ab\ncd\r\nx",
        'after the last newline, from the start of the text';
    is $line->("ab\ncd\rx", 4, 5), "ab\ncd",
        'to a carriage return after the match';
    is $line->("ab\ncdef", 1, 5), "ab\ncd", 'or to where the match ends';
    is $line->("\nab\ncd", 0, 0), "\nab",
        'and an empty match at the start, before a newline, as gitleaks has it';
};

subtest 'A generic rule\'s finding is dropped if a specific one contains it' =>
    sub {
        my @rules = (
            {id => 'generic-thing', regex => 'g=(\w+)'},
            {id => 'specific',      regex => 's=(\w+)'},
        );
        is found('g=abc s=xabcx', \@rules), [['specific', 'xabcx', 8]],
        'on the same line';
        is found("g=abc\ns=xabcx", \@rules),
        [['generic-thing', 'abc', 2], ['specific', 'xabcx', 8]], 'not another';
        is found('g=abc s=xyz', \@rules),
        [['generic-thing', 'abc', 2], ['specific', 'xyz', 8]],
        'nor one it isn\'t in';
        is found(
            'g=abc h=abc',
            [$rules[0], {id => 'generic-too', regex => 'h=(\w+)'}],
        ),
        [['generic-thing', 'abc', 2], ['generic-too', 'abc', 8]],
        'nor another generic one';
    };

subtest 'Findings come in the order they appear, then the rules\' order' =>
    sub {
        my @rules = ({id => 'b', regex => 'k(\w)'}, {id => 'a', regex => '(k)'});
        is found('xk1', \@rules), [['a', 'k', 1], ['b', '1', 2]], 'by offset';
        is found('k', [{id => 'b', regex => 'k'}, {id => 'a', regex => 'k'}]),
        [['b', 'k', 0], ['a', 'k', 0]], 'then by rule';
        is found("caf\x{e9} \x{2603} k=abc", [{id => 'u', regex => 'k=(\w+)'}]),
        [['u', 'abc', 9]], 'the offset counting characters, not bytes';
    };

subtest 'redact replaces each secret once' => sub {
    is redacted('k=abc z', [{id => 'r', regex => 'k=(\w+)'}]),
        'k=*REDACTED* z', 'the secret, not the match';
    is redacted(
        'ab12',
        [{id => 'r', regex => '(ab1)'}, {id => 's', regex => '(b12)'}],
        ),
        '*REDACTED*', 'overlapping secrets as one';
    is redacted(
        'ab12',
        [{id => 'r', regex => '(ab12)'}, {id => 's', regex => '(b1)'}],
        ),
        '*REDACTED*', 'one inside another as one';
    is redacted(
        'ab',
        [{id => 'r', regex => '(a)'}, {id => 's', regex => '(b)'}],
        ),
        '*REDACTED**REDACTED*', 'secrets side by side each';
    is redacted('y', [{id => 'r', regex => '(x)?(y)', secret_group => 1}]),
        'y', 'an empty secret leaves the text as it was';
};

done_testing;
