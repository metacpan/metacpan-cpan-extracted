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

my $titles = $books->map_by("title")->order;

subtest group => sub {
    note "Basic group";

    my $book_title__title = {
        "Leviathan Wakes"       => "Leviathan Wakes",
        "Caliban's War"         => "Caliban's War",
        "The Tree-Body Problem" => "The Tree-Body Problem",
        "The Name of the Wind"  => "The Name of the Wind",
    };
    eq_or_diff(
        { $titles->group },
        $book_title__title,
        "List context, basic group works",
    );

    note "list call, list context result";
    my @titles = @$titles;
    my $title_exists = @titles->group;
    eq_or_diff(
        $title_exists,
        $book_title__title,
        "Group by simple method call works",
    );
};

subtest group_count => sub {

    my $book_title__count = {
        "Leviathan Wakes"       => 1,
        "Caliban's War"         => 1,
        "The Tree-Body Problem" => 1,
        "The Name of the Wind"  => 2,
    };

    eq_or_diff(
        { [ @$titles, "The Name of the Wind" ]->group_count },
        $book_title__count,
        "Group count works",
    );

};



subtest group__sub_ref => sub {
    eq_or_diff(
        { $books->map_by("genre")->group(sub { 1 }) },
        {
            "Sci-fi"  => 1,
            "Fantasy" => 1,
        },
        "group with sub_ref works",
    );
};

subtest group__array => sub {
    my $genres = $books->map_by("genre");

    eq_or_diff(
        { $genres->group_array },
        {
            "Sci-fi"  => [ "Sci-fi", "Sci-fi", "Sci-fi" ],
            "Fantasy" => [ "Fantasy" ],
        },
        "group_array works",
    );
};

subtest examples => sub {
    ok(1);
};




done_testing();
