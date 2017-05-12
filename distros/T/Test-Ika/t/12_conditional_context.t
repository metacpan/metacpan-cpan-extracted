use strict;
use warnings;
use utf8;
use Test::More;
use Test::Ika;
use Test::Ika::Reporter::Test;

my $reporter = Test::Ika::Reporter::Test->new();
local $Test::Ika::REPORTER = $reporter;
my @RESULT;
{
    package sandbox;
    use Test::Ika;
    use Test::More;

    $ENV{TEST_IKA_COND1} = 1;
    undef $ENV{TEST_IKA_COND2};

    describe 'uncodition', when { 0 } => sub {
        it 'uncondition' => sub {
            push @RESULT, 'test unconditional describe';
        };
    };

    describe 'foo' => sub {
        context 'uncondition' => sub {
            it 'uncondition' => sub {
                push @RESULT, 'test uncondition';
            };
        };

        context 'cond1', when { $ENV{TEST_IKA_COND1} } => sub {
            it 'cond1' => sub {
                push @RESULT, 'test cond1';
            };
        };

        context 'cond2', when { $ENV{TEST_IKA_COND2} } => sub {
            it 'cond2' => sub {
                push @RESULT, 'test cond2';
            };
        };

        context 'cond1', 1, sub {
            it 'cond1 without coderef' => sub {
                push @RESULT, 'test cond1 without coderef';
            };
        };

        context 'cond2', 0, sub {
            it 'cond2 without coderef' => sub {
                push @RESULT, 'test cond2 without coderef';
            };
        };
    };

    runtests;
}
is(join("\n", @RESULT), join("\n", (
    # skip 'test unconditional describe'
    'test uncondition',
    'test cond1',
    # skip 'test cond2'
    'test cond1 without coderef',
    # skip 'test cond2 without coderef'
)));

done_testing;
