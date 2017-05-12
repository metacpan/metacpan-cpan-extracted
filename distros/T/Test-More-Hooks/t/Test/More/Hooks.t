use strict;
use warnings;

my $class;
BEGIN {
    use Test::More;
    $class = "Test::More::Hooks";
    use_ok $class;
}

subtest '$Level' => sub {
    is Test::More::Hooks::level, 1;

    subtest '$Level + 1' => sub {
        is Test::More::Hooks::level, 2;
    };

    is Test::More::Hooks::level, 1;

    subtest '$Level + 1' => sub {
        is Test::More::Hooks::level, 2;

        subtest '$Level + 2' => sub {
            is Test::More::Hooks::level, 3;
        };

        is Test::More::Hooks::level, 2;
    };

    is Test::More::Hooks::level, 1;
};

is Test::More::Hooks::level, 0;

subtest "before()" => sub {
    my @before = ();
    before { push @before, 1 };

    subtest "before() is executed" => sub {
        is_deeply \@before, [1];

        before { push @before, 2 };
        subtest "before() is executed that is another level" => sub {
            is_deeply \@before, [1,2];
        };

        subtest "before() is executed one more." => sub {
            is_deeply \@before, [1,2,2];
        };
    }
};

subtest "after()" => sub {
    my @after = ();
    after { push @after, 1 };

    subtest "after() is executed" => sub {
        is_deeply \@after, [];

        after { push @after, 2 };
        subtest "after() is executed that is another level" => sub {
            is_deeply \@after, [];
        };
        is_deeply \@after, [2];

        subtest "after() is executed one more." => sub {
            is_deeply \@after, [2];
        };
        is_deeply \@after, [2,2];
    };

    is_deeply \@after, [2,2,1];
};

done_testing;
