use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

subtest filter_each_subref_basic => sub {
    my $hash = { one => 1, zero => 0, two => 2, undefined => undef };
    eq_or_diff(
        scalar $hash->filter_each(),
        { one => 1, two => 2 },
        "filter_each with default 'true'",
    );
    eq_or_diff(
        scalar $hash->filter_each(sub { !! $_ }),
        { one => 1, two => 2 },
        "filter_each with subref 'true'",
    );
    eq_or_diff(
        scalar $hash->filter_each(sub { ($_ || 0) > 1 }),
        { two => 2 },
        "filter_each with subref using _",
    );
    eq_or_diff(
        scalar $hash->filter_each(sub { !! $_[1] }),
        { one => 1, two => 2 },
        "filter_each with value 'true'",
    );
    eq_or_diff(
        scalar $hash->filter_each(sub { $_[0] eq "one" }),
        { one => 1 },
        "filter_each with key eq",
    );
};

subtest filter_each_string => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->filter_each(0),
        { zero => 0 },
        "filter_each with string number 0",
    );
    eq_or_diff(
        { one => "one", zero => 0, two => 2 }->filter_each("one")->to_ref,
        { one => "one" },
        "filter_each with string",
    );
};

# TODO: undef when the old call style is gone

subtest filter_each_regex => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->filter_each(qr/2/),
        { two => 2 },
        "filter_each with regex",
    );
};

subtest filter_each_hashref_keys => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->filter_each({ 2 => 1 }),
        { two => 2 },
        "filter_each with regex",
    );
};

subtest filter_each_defined_basic => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->filter_each_defined(),
        { one => 1, two => 2, zero => 0 },
        "filter_each_defined",
    );
};

subtest grep => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->grep_each(),
        { one => 1, two => 2 },
        "grep_each with default 'true'",
    );
    eq_or_diff(
        scalar $hash->grep_each_defined(),
        { one => 1, two => 2, zero => 0 },
        "grep_each_defined",
    );
};


done_testing();
