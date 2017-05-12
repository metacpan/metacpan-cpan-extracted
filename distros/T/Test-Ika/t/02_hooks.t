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

    describe 'foo' => sub {
        before_all {
            push @RESULT, 'OUTER BEFORE';
        };
        after_all {
            push @RESULT, 'OUTER AFTER';
        };
        before_each {
            push @RESULT, 'OUTER BEFORE_EACH';
        };
        after_each {
            push @RESULT, 'OUTER AFTER_EACH';
        };
        it p => sub {
            push @RESULT, 'test p';
        };
        describe 'x' => sub {
            before_all {
                push @RESULT,  'BEFORE_ALL INNER';
            };
            after_all {
                push @RESULT,  'AFTER_ALL INNER';
            };
            before_each {
                push @RESULT, 'BEFORE_EACH INNER';
            };
            after_each {
                push @RESULT, 'AFTER_EACH INNER';
            };
            it y => sub {
                push @RESULT, 'test y';
            };
            it z => sub {
                push @RESULT, 'test z';
            };
        };
    };
    runtests;
}
is(join("\n", @RESULT), join("\n", (
    'OUTER BEFORE',
        'OUTER BEFORE_EACH',
            'test p',
        'OUTER AFTER_EACH',

        'BEFORE_ALL INNER',
            'OUTER BEFORE_EACH',
                'BEFORE_EACH INNER',
                    'test y',
                'AFTER_EACH INNER',
            'OUTER AFTER_EACH',

            'OUTER BEFORE_EACH',
                'BEFORE_EACH INNER',
                    'test z',
                'AFTER_EACH INNER',
            'OUTER AFTER_EACH',
        'AFTER_ALL INNER',
    'OUTER AFTER',
)));

done_testing;

