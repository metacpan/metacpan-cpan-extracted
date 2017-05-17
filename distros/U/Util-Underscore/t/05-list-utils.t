#!perl

use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;
use Test::Warn;

use Util::Underscore;

my %lu_aliases = qw/
    reduce      reduce
    any         any
    all         all
    none        none
    max         max
    max_str     maxstr
    min         min
    min_str     minstr
    sum         sum
    product     product
    pairgrep    pairgrep
    pairfirst   pairfirst
    pairmap     pairmap
    shuffle     shuffle
    /;

while (my ($k, $v) = each %lu_aliases) {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    ok \&{"_::$k"} == \&{"List::Util::$v"}, "_::$k == List::Util::$v";
}

my %lmu_aliases = qw/
    first       first_value
    first_index first_index
    last        last_value
    last_index  last_index
    natatime    natatime
    uniq        uniq
    part        part
    each_array  each_arrayref
    /;

while (my ($k, $v) = each %lmu_aliases) {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    ok \&{"_::$k"} == \&{"List::MoreUtils::$v"}, "_::$k == List::MoreUtils::$v";
}

# Special test for "zip":

my @xs = qw/a b c d/;
my @ys = qw/1 2 3/;
is_deeply [ _::zip \@xs, \@ys ], [ a => 1, b => 2, c => 3, d => undef ],
    '_::zip sanity test';

# max_by, max_str_by, min_by, min_str_by use a common implementation under the hood,
# Therefore, only one example is tested thoroughly.

subtest 'max_by' => sub {
    plan tests => 3;

    subtest 'scalar context' => sub {
        plan tests => 5;

        is scalar(_::max_by { $_ } 2, 3, 1), 3, "finds maximum number";

        my $count = 0;
        is scalar(_::max_by { $count++; length } qw/a ccc bb aaaa dd xxxx/),
            'aaaa', "finds maximum string";
        is $count, 6, "executed the expected number of times";

        lives_and {
            is scalar(_::max_by { die "never called" } ()), undef;
        }
        "returns undef when list is empty";

        lives_and {
            is scalar(_::max_by { die "never called" } (4)), 4;
        }
        "short circuits on single element";
    };

    subtest 'list context' => sub {
        plan tests => 5;

        is_deeply [ _::max_by { $_ } 2, 3, 1, 3, 2 ], [ 3, 3 ],
            "finds maximum numbers";

        my $count = 0;
        is_deeply [ _::max_by { $count++; length } qw/a aaa bb ccc d/ ],
            [qw/aaa ccc/], "finds maximum strings";
        is $count, 5, "executed the expected number of times";

        lives_and {
            is_deeply [ _::max_by { die "never executed" } () ], [];
        }
        "returns empty list when input list is empty";

        lives_and {
            is_deeply [ _::max_by { die "never executed" } (4) ], [4];
        }
        "short circuits on single element";
    };

    subtest 'void context' => sub {
        plan tests => 1;
        lives_ok {
            _::max_by { die "never executed" } (1, 2, 3);
            "another_statement";
        }, "not executed in void context";
    };
};

subtest 'max_str_by' => sub {
    plan tests => 1;

# we test the stringification: HASH(0x...), ARRAY(0x...), CODE(0x...)
    is_deeply scalar(_::max_str_by { "$_" } (+{}, +[], sub { })), +{},
        "finds maximum string";
};

subtest 'min_by' => sub {
    plan tests => 1;
    is scalar(_::min_by { length } qw(foo x baz)), 'x', "finds minimum string";
};

subtest 'min_str_by' => sub {
    plan tests => 1;

# twe test the stringification: HASH(0x...), ARRAY(0x...), CODE(0x...)
    is_deeply scalar(_::min_str_by { "$_" } (+{}, +[], sub { })), +[],
        "finds minimum string";
};

subtest 'uniq_by' => sub {
    plan tests => 8;

    my $count = 0;
    is_deeply [ _::uniq_by { $count++; length } qw/a b foo c bar baz/ ],
        [qw/a foo/], "correct return value";
    is $count, 6, "key function invoked the correct number of times";

    lives_and {
        is_deeply [ _::uniq_by { die "never invoked" } () ], [];
    }
    "handles empty list correctly";

    lives_and {
        is_deeply [ _::uniq_by { die "never invoked" } (42) ], [42];
    }
    "short-circuits on single element";

    is scalar(_::uniq_by { length } qw/a b foo c bar xy/), 3,
        "correct behavior in scalar context";

    is scalar(_::uniq_by { length } qw/a/), 1,
        "correct behavior in scalar context for single element";

    is scalar(_::uniq_by { length } ()), 0,
        "correct behavior in scalar context for empty input";

    warning_is {
        _::uniq_by { die "never invoked" } 1, 2, 3;
        undef;
    }
    { carped => 'Useless use of _::uniq_by in void context' },
    "warns when used in void context";
};

subtest 'classify' => sub {
    plan tests => 5;

    my $count = 0;
    is_deeply
        + { _::classify { $count++; length } qw/a b foo c bar baz/ },
        +{ 1 => [qw/a b c/], 3 => [qw/foo bar baz/] },
        "correct return value in list context";
    is $count, 6, "key function invoked correct number of times";

    is_deeply
        scalar(_::classify { length } qw/a b foo c bar baz/),
        +{ 1 => [qw/a b c/], 3 => [qw/foo bar baz/] },
        "correct return value in scalar context";

    lives_and {
        is_deeply + { _::classify { die "never invoked" } () }, +{};
    }
    "handles empty list correctly";

    warning_is {
        _::classify { die "never invoked" } 1, 2, 3;
        undef;
    }
    { carped => 'Useless use of _::classify in void context' },
    "warns when used in void context";
};
