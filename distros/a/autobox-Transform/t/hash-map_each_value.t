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

subtest map_each_value_missing_subref => sub {
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_value() },
        qr/map_each_value\(\$value_subref\): \$value_subref \(\) is not a sub ref at/,
        "map_each_value dies without subref",
    );
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_value("abc") },
        qr/map_each_value\(\$value_subref\): \$value_subref \(abc\) is not a sub ref at/,
        "map_each_value dies without subref",
    );
};

subtest map_each_value_subref_returns_wrong_number_of_items => sub {
    throws_ok(
        sub { scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_value(sub { return (1, 2) }) },
        qr/map_each_value \$value_subref returned multiple values.+?(one|zero|two|undefined)/,
        "map_each_value, multiple return values",
    );
};

subtest map_each_value_basic => sub {
    eq_or_diff(
        scalar { one => 1, zero => 0, two => 2, undefined => undef }->map_each_value(
            sub { $_[0] . ( $_ // "undef" ) },
        ),
        {
            zero      => "zero0",
            one       => "one1",
            two       => "two2",
            undefined => "undefinedundef",
        },
        "map_each_value with key, value, topic variable",
    );
};

subtest examples => sub {
    # Upper-case the genre name, and make the count say "n books"
    eq_or_diff(
        {
            $books->group_by_count("genre")->map_each_value(sub { "$_ books" })
        },
        {
            "Fantasy" => "1 books",
            "Sci-fi"  => "3 books",
        },
        "Book count",
    );

    ok(1);
};


done_testing();
