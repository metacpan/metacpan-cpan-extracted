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

subtest map_each_missing_subref => sub {
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each() },
        qr/map_each\(\$key_value_subref\): \$key_value_subref \(\) is not a sub ref at/,
        "map_each dies without subref",
    );
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each("abc") },
        qr/map_each\(\$key_value_subref\): \$key_value_subref \(abc\) is not a sub ref at/,
        "map_each dies without subref",
    );
};

subtest map_each_subref_returns_wrong_number_of_items => sub {
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each(sub { return (1) }) },
        qr|returned odd number of keys/values at|,
        "map_each, 1 return value",
    );
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each(sub { return (1, 2, 3) }) },
        qr|returned odd number of keys/values at|,
        "map_each, 3 return values",
    );
};

subtest map_each_basic => sub {
    eq_or_diff(
        scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each(
            sub { $_[0] . ( $_[1] // "undef" ), ( $_ // "UNDEF" ) },
        ),
        { zero0 => 0, one1 => 1, two2 => 2, undefinedundef => "UNDEF" },
        "map_each with key, value, topic variable",
    );
    eq_or_diff(
        scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each(
            sub { ($_[0] => $_, ($_ // "") => $_[0] ) },
        ),
        {
            one => 1, zero => 0, two => 2, undefined => undef,
            1 => "one", 0 => "zero", 2 => "two", "" => "undefined",
        },
        "map_each with multiple return pairs",
    );
};

subtest examples => sub {
    # Upper-case the genre name, and make the count say "n books"
    eq_or_diff(
        {
            $books->group_by_count("genre")->map_each(sub { uc($_[0]) => "$_ books" })
        },
        {
            "FANTASY" => "1 books",
            "SCI-FI"  => "3 books",
        },
        "Book count",
    );

    ok(1);
};


done_testing();
