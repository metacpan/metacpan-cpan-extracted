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


subtest order_by_simple => sub {
    eq_or_diff(
        $books->order_by("title")->map_by("title")->to_ref,
        $expected_titles_str,
        "order_by default everything, scalar context",
    );
    eq_or_diff(
        [ $books->order_by("title")->map_by("title") ],
        $expected_titles_str,
        "order_by default everything, list context",
    );
};


subtest order_by_num_str => sub {
    eq_or_diff(
        $books->order_by(price => "num")->map_by("price")->to_ref,
        $expected_prices_asc,
        "order_by num",
    );
    eq_or_diff(
        $books->order_by(title => "str")->map_by("title")->to_ref,
        $expected_titles_str,
        "order_by str",
    );
};


subtest order_by_asc_desc => sub {
    eq_or_diff(
        $books->order_by(title => "asc")->map_by("title")->to_ref,
        $expected_titles_str,
        "order_by str asc",
    );
    eq_or_diff(
        $books->order_by(title => "desc")->map_by("title")->to_ref,
        $expected_titles_str->reverse->to_ref,
        "order_by str desc",
    );
};

subtest order_by_method_accessor => sub {
    # Call method with dummy arg
    eq_or_diff(
        $books->order_by([ title_uc => "dummy" ])->map_by("title")->to_ref,
        $expected_titles_str,
        "order_by method call without comparison",
    );
    eq_or_diff(
        $books->order_by([ title_uc => "dummy" ] => "desc")->map_by("title")->to_ref,
        $expected_titles_str->reverse->to_ref,
        "order_by method call with comparison",
    );
};


subtest order_by_sub => sub {
    eq_or_diff(
        $books->order_by(price => [ "num", sub { 0 - $_ } ])->map_by("price")->to_ref,
        $expected_prices_asc->reverse->to_ref,
        "order_by num, subref",
    );
};


subtest order_by_regex => sub {
    eq_or_diff(
        $books->order_by(title => qr/(.)$/)->map_by("title")->to_ref,
        $expected_titles_regex,
        "order_by regex",
    );
};


subtest order_by_multiple_options__num_desc => sub {
    eq_or_diff(
        $books->order_by(price => [ "num", "desc" ])->map_by("price")->to_ref,
        $expected_prices_asc->reverse->to_ref,
        "order_by num, desc",
    );
};

subtest accessor_missing => sub {
    throws_ok(
        sub { $books->order_by() },
        qr/\Q->order_by() missing argument:\E \$accessor/,
        "Missing arg dies ok",
    );
};

subtest comparison_args_validation => sub {
    throws_ok(
        sub { $books->order_by(title => "blah")->to_ref },
        qr/\Q->order_by(): Invalid comparison option (blah)/,
        "Invalid arg dies ok",
    );
    throws_ok(
        sub { [1]->order_by(title => [ "asc", "desc" ])->to_ref },
        qr/\Q->order_by(): Conflicting comparison options: (asc) and (desc)/,
        "Invalid arg dies ok",
    );
    # Ignore ugly subref vs regex for now
};

subtest order_by_multiple_comparisons => sub {
    my $words = [
        "abc",
        "def",
        "ABC",
        "DEF",
        "Abc",
    ]->map(sub { { word => $_ }});
    # ASCII order is UPPER before lower
    my $expected_words = [
        "DEF",
        "def",
        "ABC",
        "Abc",
        "abc",
    ];
    eq_or_diff(
        $words->order_by(
            word => [ desc => sub { uc($_) } ],
            word => qr/(.+)/,
        )->map_by("word")->to_ref,
        $expected_words,
        "First reverse uc, then whole match cmp",
    );
};

subtest examples => sub {
    my $titles = [
        "Leviathan Wakes",
        "The Name of the Wind",
        "The Tree-Body Problem",
        "Caliban's War",
        "The Butcher of Anderson Station",
    ];
    my $expected_titles = [
        "The Butcher of Anderson Station",
        "Caliban's War",
        "Leviathan Wakes",
        "The Name of the Wind",
        "The Tree-Body Problem",
    ];
    eq_or_diff(
        $titles->order( qr/^ (?: The \s+ )? (.+) /x )->to_ref,
        $expected_titles,
        "regex to remove leading article",
    );
};



done_testing();



