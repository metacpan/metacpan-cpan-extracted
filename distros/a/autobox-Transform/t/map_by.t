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
my $books      = $literature->{books};
my $authors    = $literature->{authors};
my $reviews    = $literature->{reviews};


subtest map_by__empty => sub {
    note "Empty arrayref with method args";
    eq_or_diff(
        [ []->map_by(genre => [ 34 ]) ],
        [
        ],
        "Empty list gives empty list",
    );
    eq_or_diff(
        [ []->map_by([ genre => 34 ]) ],
        [
        ],
        "Empty list gives empty list",
    );
};

### method

subtest map_by__method => sub {
    note "ArrayRef call, list context result";
    eq_or_diff(
        [ $books->map_by("genre") ],
        [
            "Sci-fi",
            "Sci-fi",
            "Sci-fi",
            "Fantasy",
        ],
        "Map by simple method call works",
    );

    note "list call, list context result";
    my @books = @$books;
    my $genres = @books->map_by("genre");
    eq_or_diff(
        $genres,
        [
            "Sci-fi",
            "Sci-fi",
            "Sci-fi",
            "Fantasy",
        ],
        "Map by simple method call works",
    );

    note "ArrayRef call, arrayref accessor";
    eq_or_diff(
        [ $books->map_by([ "genre" ]) ],
        [
            "Sci-fi",
            "Sci-fi",
            "Sci-fi",
            "Fantasy",
        ],
        "Map by simple method call works",
    );
};

subtest map_by__missing_method => sub {
    throws_ok(
        sub { $books->map_by() },
        qr{^->map_by\(\)[ ]missing[ ]argument:[ ]\$accessor \s at .+? t.map_by.t }x,
        "Missing arg croaks from the caller, not from the lib"
    )
};

subtest map_by__method__not_a_method => sub {
    # Invalid arg, not a method
    throws_ok(
        sub { $books->map_by("not_a_method") },
        qr{ not_a_method .+? Book .+? t.map_by.t }x,
        "Missing method croaks from the caller, not from the lib",
    )
};

subtest map_by__method__args => sub {
    eq_or_diff(
        [ $authors->map_by(publisher_affiliation => ["with"]) ],
        [
            'James A. Corey with Orbit',
            'Cixin Liu with Head of Zeus',
            'Patrick Rothfuss with Gollanz',
        ],
        "map_by with argument list",
    );
    eq_or_diff(
        [ $authors->map_by([ publisher_affiliation => "with" ]) ],
        [
            'James A. Corey with Orbit',
            'Cixin Liu with Head of Zeus',
            'Patrick Rothfuss with Gollanz',
        ],
        "map_by with argument list",
    );
};

subtest map_by__method__args__invalid_type => sub {
    throws_ok(
        sub { $authors->map_by(publisher_affiliation => 342) },
        qr{ map_by .+? 'publisher_affiliation' .+? \@args .+? \(342\) .+? list .+? t.map_by.t}x,
        "map_by with argument which isn't an array ref",
    );
};


### hash key

subtest map_by__key => sub {
    note "ArrayRef key, list context result";
    eq_or_diff(
        [ $reviews->map_by("score") ],
        [ 7, 6, 9 ],
        "Map by key call works",
    );
};

subtest map_by__key__with_args => sub {
    note "ArrayRef key, list context result";
    throws_ok(
        sub { $reviews->map_by([ "score" => "abc" ]) },
        qr{ map_by .+? 'score' .+? \@args .+? only[ ]supported[ ]for[ ]method[ ]calls.+? t.map_by.t}x,
        "Arrayref with items, not allowed"
    );
    lives_ok(
        sub { $reviews->map_by("score" => [ ]) },
        "Empty arrayref is allowed",
    );

    throws_ok(
        sub { $reviews->map_by([ "score" => "abc" ]) },
        qr{ map_by .+? 'score' .+? \@args .+? only[ ]supported[ ]for[ ]method[ ]calls.+? t.map_by.t}x,
        "Arrayref with items, not allowed"
    );
    lives_ok(
        sub { $reviews->map_by([ "score" ]) },
        "No args is allowed",
    );
};



subtest examples => sub {

    my $tax_pct = 0.15;
    my $total_order_amount = $books
        ->map_by(price_with_tax => [ $tax_pct ])
        ->sum;
    my $total_order_amount2 = $books
        ->map_by([ price_with_tax => $tax_pct ])
        ->sum;
    is($total_order_amount, 32.2, "total_order_amount");


    my $order_authors = $books
        ->map_by("author")
        ->map_by("name")
        ->uniq->sort->join(", ");
    is(
        $order_authors,
        "Cixin Liu, James A. Corey, Patrick Rothfuss",
        "order_authors ok",
    )
};

subtest "map_by can use autobox::Core methods" => sub {
    my $messages = [
        "Hello world",
        "    Hello  space  ",
    ];
    eq_or_diff(
        scalar $messages->map_by("strip"),
        [
            "Hello world",
            "Hello  space",
        ],
        "Called autobox::Core String->strip",
    )
};




done_testing();
