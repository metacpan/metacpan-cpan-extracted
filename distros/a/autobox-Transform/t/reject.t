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

subtest reject_default_true => sub {
    note "Default is checking for true";
    my $array = [ 0, 1, 2, 3, "", 4, undef, 5 ];
    eq_or_diff(
        $array->reject->to_ref,
        [ 0, "", undef ],
        "Only false values remain",
    );
};

subtest reject_invalid_predicate => sub {
    my $strings = [ "abc", "def", "abc" ];
    throws_ok(
        sub { $strings->reject(\"abc")->to_ref },
        qr/->reject .+? \$predicate: .+?\Q is not one of: subref, string, regex/x,
        "Invalid predicate type",
    );
};

subtest reject_subref => sub {
    note "ArrayRef call, list context result, subref predicate";
    eq_or_diff(
        [ map { $_->name } $authors->reject(sub { $_->is_prolific }) ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject simple method call works",
    );

    note "list call, list context result";
    my @authors = @$authors;
    my $prolific_authors = @authors->reject(sub { $_->is_prolific });
    eq_or_diff(
        [ map { $_->name } @$prolific_authors ],
        [
            "Cixin Liu",
            "Patrick Rothfuss",
        ],
        "reject simple method call works",
    );
};

subtest reject_string => sub {
    my $strings = [ "abc", "def", "abc" ];
    eq_or_diff(
        $strings->reject("abc")->to_ref,
        [ "def" ],
        "reject scalar string",
    );
    # TODO: deal with undef comparisons
};

# TODO: Can't work until the old call style is removed.
# subtest reject_undef => sub {
#     my $strings = [ "abc", undef, "abc" ];
#     eq_or_diff(
#         $strings->reject(undef)->to_ref,
#         [ "abc", "abc" ],
#         "reject undef",
#     );
# };

subtest reject_regex => sub {
    my $strings = [ "abc", "def", "abc" ];
    eq_or_diff(
        $strings->reject(qr/a/)->to_ref,
        [ "def" ],
        "reject regex",
    );
    eq_or_diff(
        $strings->reject(qr/A/)->to_ref,
        [ "abc", "def", "abc"],
        "reject regex miss",
    );
    eq_or_diff(
        $strings->reject(qr/A/i)->to_ref,
        [ "def" ],
        "reject regex with flags",
    );
    # TODO: deal with undef comparisons
};

subtest reject_hashref_keys => sub {
    my $strings = [ "abc", "def", "ghi" ];
    eq_or_diff(
        $strings->reject({ abc => undef, def => 1 })->to_ref,
        [ "ghi" ],
        "reject hashref keys (exists, not true hash value)",
    );
    # TODO: deal with undef comparisons
};


done_testing();
