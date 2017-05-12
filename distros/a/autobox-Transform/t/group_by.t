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

subtest group_by__method => sub {
    note "ArrayRef call, list context result";

    my $book_object = {
        "Leviathan Wakes"       => $books->[0],
        "Caliban's War"         => $books->[1],
        "The Tree-Body Problem" => $books->[2],
        "The Name of the Wind"  => $books->[3],
    };
    eq_or_diff(
        { $books->group_by("title") },
        $book_object,
        "Group by simple method call works",
    );

    note "list call, list context result";
    my @books = @$books;
    my $genre_exists = @books->group_by("title");
    eq_or_diff(
        $genre_exists,
        $book_object,
        "Group by simple method call works",
    );

    note "Call with arrayref accessor";
    eq_or_diff(
        { $books->group_by([ "title" ]) },
        $book_object,
        "Group by simple method call works",
    );
};

subtest group_by__key => sub {
    note "ArrayRef key lookup";
    eq_or_diff(
        { $reviews->group_by("id") },
        {
            1 => { id => 1, score => 7 },
            2 => { id => 2, score => 6 },
            3 => { id => 3, score => 9 },
        },
        "Group by simple hash key lookup works",
    );
};

subtest group_by__key__with_args => sub {
    note "ArrayRef key lookup";
    throws_ok(
        sub { $reviews->group_by("id" => 32) },
        qr{ group_by .+? 'id' .+? \@args .+? \(32\) .+? only[ ]supported[ ]for .+? t.group_by.t}x,
        "Group by simple hash key lookup with args dies as expected",
    );
};

subtest group_by_count__method => sub {
    note "ArrayRef call, list context result";

    my $genre_count = {
        "Sci-fi"  => 3,
        "Fantasy" => 1,
    };

    eq_or_diff(
        { $books->group_by_count("genre") },
        $genre_count,
        "Group by simple method call works",
    );

    note "list call, list context result";
    my @books = @$books;
    my $genre_exists = @books->group_by_count("genre");
    eq_or_diff(
        $genre_exists,
        $genre_count,
        "Group by simple method call works",
    );
};



subtest group_by__missing_method => sub {
    throws_ok(
        sub { $books->group_by() },
        qr{^->group_by\(\)[ ]missing[ ]argument:[ ]\$accessor \s at .+? t.group_by.t }x,
        "Missing arg croaks from the caller, not from the lib"
    );
};

subtest group_by__not_a_method => sub {
    # Invalid arg, not a method
    throws_ok(
        sub { $books->group_by("not_a_method") },
        qr{ not_a_method .+? Book .+? t.group_by.t }x,
        "Missing method croaks from the caller, not from the lib",
    );
};

subtest group_by__method__args => sub {
    eq_or_diff(
        { $authors->group_by_count(publisher_affiliation => ["with"]) },
        {
            'James A. Corey with Orbit'     => 1,
            'Cixin Liu with Head of Zeus'   => 1,
            'Patrick Rothfuss with Gollanz' => 1,
        },
        "group_by with argument list",
    );
    eq_or_diff(
        { $authors->group_by_count([publisher_affiliation => "with"]) },
        {
            'James A. Corey with Orbit'     => 1,
            'Cixin Liu with Head of Zeus'   => 1,
            'Patrick Rothfuss with Gollanz' => 1,
        },
        "group_by with argument list",
    );
};

subtest group_by__method__args__invalid_type => sub {
    throws_ok(
        sub { $authors->group_by(publisher_affiliation => 342) },
        qr{ group_by .+? 'publisher_affiliation' .+? \@args .+? \(342\) .+? list .+? t.group_by.t}x,
        "group_by with argument which isn't an array ref",
    );
};

subtest group_by_count__method__args__invalid_type => sub {
    throws_ok(
        sub { $authors->group_by_count(publisher_affiliation => 342) },
        qr{ group_by .+? 'publisher_affiliation' .+? \@args .+? \(342\) .+? list .+? t.group_by.t}x,
        "group_by with argument which isn't an array ref",
    );
};

subtest group_by__sub_ref => sub {
    eq_or_diff(
        { $books->group_by("genre", [], sub { 1 }) },
        {
            "Sci-fi"  => 1,
            "Fantasy" => 1,
        },
        "group_by with sub_ref works",
    );
    eq_or_diff(
        { $books->group_by([ "genre" ], sub { 1 }) },
        {
            "Sci-fi"  => 1,
            "Fantasy" => 1,
        },
        "group_by with sub_ref works",
    );
};

subtest group_by__method__array => sub {
    my $genre_books = $books->group_by_array("genre");
    my $genre_books2 = $books->group_by_array([ "genre" ]);
    eq_or_diff($genre_books, $genre_books2, "Same output");

    my $genre_book_titles = {
        map {
            $_ => $genre_books->{$_}->map_by("title")->sort->join(", ");
        }
        $genre_books->keys
    };

    eq_or_diff(
        $genre_book_titles,
        {
            "Sci-fi"  => "Caliban's War, Leviathan Wakes, The Tree-Body Problem",
            "Fantasy" => "The Name of the Wind",
        },
        "group_by_array work",
    );
};

subtest examples => sub {
    ok(1);
};




done_testing();
