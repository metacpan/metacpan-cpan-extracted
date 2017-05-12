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

subtest filter_by => sub {
    note "ArrayRef call, list context result, default predicate (true)";
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("is_prolific") ],
        [
            "James A. Corey",
        ],
        "filter_by simple method call works",
    );

    note "list call, list context result";
    my @authors = @$authors;
    my $prolific_authors = @authors->filter_by("is_prolific");
    eq_or_diff(
        [ map { $_->name } @$prolific_authors ],
        [
            "James A. Corey",
        ],
        "filter_by simple method call works",
    );
};

subtest grep_by => sub {
    eq_or_diff(
        [ map { $_->name } $authors->grep_by("is_prolific") ],
        [
            "James A. Corey",
        ],
        "grep_by alias works",
    );
};

subtest filter_by_with_arrayref_accessor => sub {
    note "Call with arrayref accessor without args";
    eq_or_diff(
        [ map { $_->name } $authors->filter_by([ "is_prolific" ]) ],
        [
            "James A. Corey",
        ],
        "filter_by simple method call works",
    );
};

subtest filter_by_with_predicate_subref => sub {
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", undef, sub { /Corey/ }) ],
        [
            "James A. Corey",
        ],
        "filter_by without predicate argument and with predicate sub call works",
    );
    eq_or_diff(
        [
            map { $_->name } $authors->filter_by(
                "publisher_affiliation",
                [ "with" ],
                sub { /Corey/ },
            ),
        ],
        [
            "James A. Corey",
        ],
        "filter_by with method argument and predicate sub call works",
    );

    note "Arrayref accessor";
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", sub { /Corey/ }) ],
        [
            "James A. Corey",
        ],
        "filter_by without predicate argument and with predicate sub call works",
    );
    eq_or_diff(
        [
            map { $_->name } $authors->filter_by(
                [ publisher_affiliation => "with" ],
                sub { /Corey/ },
            ),
        ],
        [
            "James A. Corey",
        ],
        "filter_by with method argument and predicate sub call works",
    );
};

subtest filter_by_with_predicate_string => sub {
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", "James A. Corey") ],
        [ "James A. Corey" ],
        "filter_by predicate string works",
    );
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", undef, "James A. Corey") ],
        [ "James A. Corey" ],
        "filter_by predicate string works, with old call style",
    );
};

# TODO: undef can't work until old call style is removed

subtest filter_by_with_predicate_regex => sub {
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", qr/corey/i) ],
        [ "James A. Corey" ],
        "filter_by predicate regex works",
    );
};

subtest filter_by_with_predicate_hashref => sub {
    eq_or_diff(
        [ map { $_->name } $authors->filter_by("name", { "James A. Corey" => 1 }) ],
        [ "James A. Corey" ],
        "filter_by predicate hashref works",
    );
};



subtest examples => sub {
    my $prolific_author_book_titles = $authors->filter_by("is_prolific")
        ->map_by("books")->flat
        ->map_by("title")->sort;
    eq_or_diff(
        $prolific_author_book_titles,
        [
            "Caliban's War",
            "Leviathan Wakes"
        ],
        "prolific_author_book_titles",
    );
};




done_testing();
