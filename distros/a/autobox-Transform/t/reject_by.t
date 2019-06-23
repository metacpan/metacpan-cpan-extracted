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

subtest reject_by => sub {
    note "ArrayRef call, list context result, default predicate (true)";
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("is_prolific") ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by simple method call works",
    );

    note "list call, list context result";
    my @authors = @$authors;
    my $prolific_authors = @authors->reject_by("is_prolific");
    eq_or_diff(
        [ map { $_->name } @$prolific_authors ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by simple method call works",
    );
};

subtest reject_by_with_arrayref_accessor => sub {
    note "Call with arrayref accessor without args";
    eq_or_diff(
        [ map { $_->name } $authors->reject_by([ "is_prolific" ]) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by simple method call works",
    );
};

subtest reject_by_with_predicate_subref => sub {
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", undef, sub { /Corey/ }) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by without predicate argument and with predicate sub call works",
    );
    eq_or_diff(
        [
            map { $_->name } $authors->reject_by(
                "publisher_affiliation",
                [ "with" ],
                sub { /Corey/ },
            ),
        ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by with method argument and predicate sub call works",
    );

    note "Arrayref accessor";
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", sub { /Corey/ }) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by without predicate argument and with predicate sub call works",
    );
    eq_or_diff(
        [
            map { $_->name } $authors->reject_by(
                [ publisher_affiliation => "with" ],
                sub { /Corey/ },
            ),
        ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by with method argument and predicate sub call works",
    );
};

subtest reject_by_with_predicate_string => sub {
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", "James A. Corey") ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by predicate string works",
    );
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", undef, "James A. Corey") ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by predicate string works, with old call style",
    );
};

# TODO: undef can't work until old call style is removed

subtest reject_by_with_predicate_regex => sub {
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", qr/corey/i) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by predicate regex works",
    );
};

subtest reject_by_with_predicate_hashref => sub {
    eq_or_diff(
        [ map { $_->name } $authors->reject_by("name", { "James A. Corey" => 1 }) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject_by predicate hashref works",
    );
};



subtest examples => sub {
    my $prolific_author_book_titles = $authors->reject_by("is_prolific")
        ->map_by("books")->flat
        ->map_by("title")->sort;
    eq_or_diff(
        $prolific_author_book_titles,
        [
            "The Name of the Wind",
            "The Tree-Body Problem",
        ],
        "non-prolific_author_book_titles",
    );
};




done_testing();
