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

subtest map_each_to_array_missing_subref => sub {
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_to_array() },
        qr/map_each_to_array\(\$array_item_subref\): \$array_item_subref \(\) is not a sub ref at/,
        "map_each_to_array dies without subref",
    );
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_to_array("abc") },
        qr/map_each_to_array\(\$array_item_subref\): \$array_item_subref \(abc\) is not a sub ref at/,
        "map_each_to_array dies without subref",
    );
};

subtest map_each_to_array_basic => sub {
    eq_or_diff(
        scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_to_array(
            sub { $_[0] . ( $_[1] // "undef" ) . ( $_ // "UNDEF" ) },
        ),
        [ "one11", "two22", "undefinedundefUNDEF", "zero00" ],
        "map_each_to_array with key, value, topic variable",
    );
};

subtest map_each_to_array_return_many_items => sub {
    eq_or_diff(
        scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_to_array(
            sub { $_[0] . ( $_[1] // "undef" ), ( $_ // "UNDEF" ) },
        ),
        [ "one1", "1", "two2", "2", "undefinedundef", "UNDEF", "zero0", "0" ],
        "map_each_to_array with key, value, topic variable",
    );
};

subtest examples => sub {
    my $genre_count = $books->group_by_count("genre");

    # Summarize each genre
    eq_or_diff(
        [ $genre_count->map_each_to_array(sub { "$_: $_[0]" }) ],
        [ "1: Fantasy", "3: Sci-fi" ],
        "Book count",
    );

    ok(1);
};

done_testing();
