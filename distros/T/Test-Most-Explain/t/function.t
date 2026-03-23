use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Warnings;
use Test::Deep;

# Fully qualified calls only — white‑box testing
BEGIN { use_ok('Test::Most::Explain') }

#------------------------------------------------------------
# _first_diff_pos
#------------------------------------------------------------
subtest '_first_diff_pos' => sub {

    is(
        Test::Most::Explain::_first_diff_pos('foo', 'foo'),
        -1,
        'identical strings return -1'
    );

    is(
        Test::Most::Explain::_first_diff_pos('foo', 'fob'),
        2,
        'first differing character detected'
    );

    is(
        Test::Most::Explain::_first_diff_pos('foo', 'foobar'),
        3,
        'shorter string mismatch at end'
    );

    is(
        Test::Most::Explain::_first_diff_pos('foobar', 'foo'),
        3,
        'longer string mismatch at end'
    );
};

#------------------------------------------------------------
# _is_deep
#------------------------------------------------------------
subtest '_is_deep' => sub {

    my $raw = '[1,2,3]';

    ok(!Test::Most::Explain::_is_deep('foo'), 'scalar is not deep');

    my $res = Test::Most::Explain::_is_deep($raw);

    ok($res, 'raw array dump is deep');

    ok(Test::Most::Explain::_is_deep('{a=>1}'), 'raw hash dump is deep');
    ok(Test::Most::Explain::_is_deep('bless({}, "X")'), 'blessed ref is deep');

    ok(!Test::Most::Explain::_is_deep("'[1,2,3]'"), 'quoted array dump is NOT deep');
};

#------------------------------------------------------------
# _extract_got_expected
#------------------------------------------------------------
subtest '_extract_got_expected' => sub {

    my @msg = (
        "Failed test 'x'\n",
        "#          got: 'foo'\n",
        "#     expected: 'bar'\n",
    );

    my ($got, $exp) = Test::Most::Explain::_extract_got_expected(@msg);

    is($got, "'foo'", 'got extracted correctly');
    is($exp, "'bar'", 'expected extracted correctly');
};

#------------------------------------------------------------
# _extract_keys
#------------------------------------------------------------
subtest '_extract_keys' => sub {

    my %keys = Test::Most::Explain::_extract_keys("{ 'a' => 1, 'b' => 2 }");

    cmp_deeply(
        \%keys,
        { a => 1, b => 1 },
        'keys extracted from hash dump'
    );
};

# Utility: capture diag output
sub capture_diag (&) {
    my ($code) = @_;
    my @out;
    {
        no warnings 'redefine';
        my $orig = \&Test::Builder::diag;
        local *Test::Builder::diag = sub {
            my ($self, @msg) = @_;
            push @out, @msg;
        };
        $code->();
    }
    return join '', @out;
}

#------------------------------------------------------------
# _looks_like_test_more_failure
#------------------------------------------------------------
subtest '_looks_like_test_more_failure' => sub {

    ok(
        Test::Most::Explain::_looks_like_test_more_failure("Failed test 'x'"),
        'detects Failed test'
    );

    ok(
        Test::Most::Explain::_looks_like_test_more_failure("#     got: 'foo'"),
        'detects got:'
    );

    ok(
        Test::Most::Explain::_looks_like_test_more_failure("# expected: 'bar'"),
        'detects expected:'
    );

    ok(
        !Test::Most::Explain::_looks_like_test_more_failure("normal diag"),
        'non-Test::More diag not detected'
    );
};

#------------------------------------------------------------
# _emit_scalar_context
#------------------------------------------------------------
subtest '_emit_scalar_context' => sub {

    my $out = capture_diag {
        Test::Most::Explain::_emit_scalar_context("abcdef", "abcXYZ", 3);
    };

    like($out, qr/Context around mismatch/, 'context header');
    like($out, qr/\.\.\.def/, 'got context extracted');
    like($out, qr/\.\.\.XYZ/, 'expected context extracted');
};

#------------------------------------------------------------
# _emit_scalar_hints
#------------------------------------------------------------
subtest '_emit_scalar_hints' => sub {

    my $out = capture_diag {
        Test::Most::Explain::_emit_scalar_hints("foo", "FOO");
    };

    like($out, qr/Possible causes/, 'hints header');
    like($out, qr/Case differs/i, 'case-difference hint detected');
};

#------------------------------------------------------------
# _explain_scalar
#------------------------------------------------------------
subtest '_explain_scalar' => sub {

    my $out = capture_diag {
        Test::Most::Explain::_explain_scalar("foo", "fob");
    };

    like($out, qr/Scalar comparison failed/, 'scalar diff header');
    like($out, qr/Got:\s+foo/, 'got shown');
    like($out, qr/Expected:\s+fob/, 'expected shown');
    like($out, qr/First difference at index 2/, 'index shown');
};

#------------------------------------------------------------
# _emit_deep_hints
#------------------------------------------------------------
subtest '_emit_deep_hints' => sub {

    my $out = capture_diag {
        Test::Most::Explain::_emit_deep_hints("{'a'=>1}", "{'a'=>1,'b'=>2}");
    };

    like($out, qr/Possible causes/, 'deep hints header');
    like($out, qr/Missing key in got: b/, 'missing key detected');
};

#------------------------------------------------------------
# _explain_deep
#------------------------------------------------------------
subtest '_explain_deep' => sub {
	my $out = capture_diag {
		Test::Most::Explain::_explain_deep("[1,2]", "[1,9]");
	};

	like($out, qr/Deep structure comparison failed/, 'deep diff header');

	like($out, qr/Got:\s* \[1,2\] /, 'got shown');

	like($out, qr/Expected:\s* \[1,9\] /, 'expected shown');
};

#------------------------------------------------------------
# _emit_explain (diag hook path)
#------------------------------------------------------------
subtest '_emit_explain' => sub {

    my @msg = (
        "Failed test 'x'",
        "#     got: 'foo'",
        "# expected: 'bar'",
    );

    my $out = capture_diag {
        Test::Most::Explain::_emit_explain(@msg);
    };

    like($out, qr/Scalar comparison failed/, 'scalar diff triggered');
    like($out, qr/foo/, 'got extracted');
    like($out, qr/bar/, 'expected extracted');
};

done_testing;
