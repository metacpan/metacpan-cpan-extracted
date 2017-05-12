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

    describe 'foo' => sub {
        it 'uncondition' => sub {
            push @RESULT, 'test uncondition';
        };

        it 'foo', when { $ENV{TEST_IKA_COND1} } => sub {
            push @RESULT, 'test foo';
        };

        it 'bar', when { $ENV{TEST_IKA_COND2} } => sub {
            push @RESULT, 'test bar';
        };

        it 'baz', 1 => sub {
            push @RESULT, 'test baz';
        };

        it 'quux', 0 => sub {
            push @RESULT, 'test quux';
        };
    };

    runtests;
}
is(join("\n", @RESULT), join("\n", (
    'test uncondition',
    'test foo',
    # skip test bar
    'test baz',
    # skip test quux
)));

done_testing;
