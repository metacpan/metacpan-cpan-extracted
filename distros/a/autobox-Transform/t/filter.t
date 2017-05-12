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

subtest filter_default_true => sub {
    note "Default is checking for true";
    my $array = [ 0, 1, 2, 3, "", 4, undef, 5 ];
    eq_or_diff(
        $array->filter->to_ref,
        [ 1, 2, 3, 4, 5 ],
        "Only true values remain",
    );
};

subtest filter_invalid_predicate => sub {
    my $strings = [ "abc", "def", "abc" ];
    throws_ok(
        sub { $strings->filter(\"abc")->to_ref },
        qr/->filter .+? \$predicate: .+?\Q is not one of: subref, string, regex/x,
        "Invalid predicate type",
    );
};

subtest filter_subref => sub {
    note "ArrayRef call, list context result, subref predicate";
    eq_or_diff(
        [ map { $_->name } $authors->filter(sub { $_->is_prolific }) ],
        [
            "James A. Corey",
        ],
        "filter simple method call works",
    );

    note "list call, list context result";
    my @authors = @$authors;
    my $prolific_authors = @authors->filter(sub { $_->is_prolific });
    eq_or_diff(
        [ map { $_->name } @$prolific_authors ],
        [
            "James A. Corey",
        ],
        "filter simple method call works",
    );
};

subtest filter_string => sub {
    my $strings = [ "abc", "def", "abc" ];
    eq_or_diff(
        $strings->filter("abc")->to_ref,
        [ "abc", "abc" ],
        "filter scalar string",
    );
    # TODO: deal with undef comparisons
};

# TODO: Can't work until the old call style is removed.
# subtest filter_undef => sub {
#     my $strings = [ "abc", undef, "abc" ];
#     eq_or_diff(
#         $strings->filter(undef)->to_ref,
#         [ undef ],
#         "filter undef",
#     );
# };

subtest filter_regex => sub {
    my $strings = [ "abc", "def", "abc" ];
    eq_or_diff(
        $strings->filter(qr/a/)->to_ref,
        [ "abc", "abc" ],
        "filter regex",
    );
    eq_or_diff(
        $strings->filter(qr/A/)->to_ref,
        [ ],
        "filter regex miss",
    );
    eq_or_diff(
        $strings->filter(qr/A/i)->to_ref,
        [ "abc", "abc" ],
        "filter regex with flags",
    );
    # TODO: deal with undef comparisons
};

subtest filter_hashref_keys => sub {
    my $strings = [ "abc", "def", "ghi" ];
    eq_or_diff(
        $strings->filter({ abc => undef, def => 1 })->to_ref,
        [ "abc", "def" ],
        "filter hashref keys (exists, not true hash value)",
    );
    # TODO: deal with undef comparisons
};


done_testing();
