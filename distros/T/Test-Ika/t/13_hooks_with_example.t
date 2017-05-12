use strict;
use warnings;
use utf8;
use Test::More;
use Test::Ika;
use Test::Ika::Reporter::Test;

my $reporter = Test::Ika::Reporter::Test->new();
local $Test::Ika::REPORTER = $reporter;

my (@BEFORE, @AFTER);
{
    package sandbox;
    use Test::Ika;
    use Test::More;

    describe 'foo' => sub {
        before_each {
            my ($example) = @_;
            push @BEFORE, $example;
        };
        after_each {
            my ($example) = @_;
            push @AFTER, $example;
        };
        it 'success' => sub { ok 1 };
        it 'failure' => sub { ok 0 };
        it 'not implemented';
        xit 'disabled' => sub { ok 1 };
    };
    runtests;
}

subtest 'before_each' => sub {
    is_deeply [ "success", "failure", "not implemented", "disabled" ], [ map { $_->name } @BEFORE ];
};

subtest 'after_each' => sub {
    subtest 'success case' => sub {
        my $example = $AFTER[0];
        is $example->name, "success";

        ok $example->result;
        ok !$example->skip;

        ok $example->output;
        ok !$example->error;
    };

    subtest 'failure case' => sub {
        my $example = $AFTER[1];
        is $example->name, "failure";

        ok !$example->result;
        ok !$example->skip;

        ok $example->output;
        ok !$example->error;
    };

    subtest 'not implemented case' => sub {
        my $example = $AFTER[2];
        is $example->name, "not implemented";

        ok $example->result;
        ok $example->skip;

        ok $example->output;
        ok !$example->error;
    };

    subtest 'disabled case' => sub {
        my $example = $AFTER[3];
        is $example->name, "disabled";

        ok $example->result;
        ok $example->skip;

        ok $example->output;
        ok !$example->error;
    };
};

done_testing;

