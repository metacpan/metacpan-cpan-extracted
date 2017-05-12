use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

use lib "t/lib";
use Literature;

my $literature = Literature::literature();
my $authors    = $literature->{authors};
my $books      = $literature->{books};

my $expected_titles_str = [
    "Caliban's War",
    "Leviathan Wakes",
    "The Name of the Wind",
    "The Tree-Body Problem",
];

# order by last char
my $expected_titles_regex = [
    "The Name of the Wind",
    "The Tree-Body Problem",
    "Caliban's War",
    "Leviathan Wakes",
];

my $expected_prices_asc = [ 5, 6, 6, 11 ];

subtest order_simple => sub {
    eq_or_diff(
        $books->map_by("title")->order->to_ref,
        $expected_titles_str,
        "order default everything, scalar context",
    );
    eq_or_diff(
        [ $books->map_by("title")->order ],
        $expected_titles_str,
        "order default everything, list context",
    );
};

subtest order_num_str => sub {
    eq_or_diff(
        $books->map_by("price")->order("num")->to_ref,
        $expected_prices_asc,
        "order num",
    );
    eq_or_diff(
        $books->map_by("title")->order("str")->to_ref,
        $expected_titles_str,
        "order str",
    );
};

subtest order_asc_desc => sub {
    eq_or_diff(
        $books->map_by("title")->order("asc")->to_ref,
        $expected_titles_str,
        "order str asc",
    );
    eq_or_diff(
        $books->map_by("title")->order("desc")->to_ref,
        $expected_titles_str->reverse->to_ref,
        "order str desc",
    );
};

subtest order_sub => sub {
    eq_or_diff(
        $books->map_by("price")->order([ "num", sub { 0 - $_ } ])->to_ref,
        $expected_prices_asc->reverse->to_ref,
        "order num, subref",
    );
};

subtest order_regex => sub {
    eq_or_diff(
        $books->map_by("title")->order(qr/(.)$/)->to_ref,
        $expected_titles_regex->to_ref,
        "order regex",
    );
};

subtest order_multiple_options__num_desc => sub {
    eq_or_diff(
        $books->map_by("price")->order([ "num", "desc" ])->to_ref,
        $expected_prices_asc->reverse->to_ref,
        "order num, desc",
    );
};

subtest comparison_args_validation => sub {
    throws_ok(
        sub { [1]->order("blah")->to_ref },
        qr/\Q->order(): Invalid comparison option (blah)/,
        "Invalid arg dies ok",
    );
    throws_ok(
        sub { [1]->order([ "asc", "desc" ])->to_ref },
        qr/\Q->order(): Conflicting comparison options: (asc) and (desc)/,
        "Invalid arg dies ok",
    );
    # Ignore ugly subref vs regex for now
};

subtest order_multiple_comparisons => sub {
    my $words = [
        "abc",
        "def",
        "ABC",
        "DEF",
        "Abc",
    ];
    # ASCII order is UPPER before lower
    my $expected_words = [
        "DEF",
        "def",
        "ABC",
        "Abc",
        "abc",
    ];
    eq_or_diff(
        $words->order(
            [ desc => sub { uc($_) } ],
            qr/(.+)/,
        )->to_ref,
        $expected_words,
        "First reverse uc, then whole match cmp",
    );
};



done_testing();
