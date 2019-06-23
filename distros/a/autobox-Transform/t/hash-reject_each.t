use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

subtest reject_each_subref_basic => sub {
    my $hash = { one => 1, zero => 0, two => 2, undefined => undef };
    eq_or_diff(
        scalar $hash->reject_each(),
        { zero => 0, undefined => undef },
        "reject_each with default 'false'",
    );
    eq_or_diff(
        scalar $hash->reject_each(sub { !! $_ }),
        { zero => 0, undefined => undef },
        "reject_each with subref 'false'",
    );
    eq_or_diff(
        scalar $hash->reject_each(sub { ($_ || 0) > 1 }),
        { one => 1, zero => 0, undefined => undef },
        "reject_each with subref using _",
    );
    eq_or_diff(
        scalar $hash->reject_each(sub { !! $_[1] }),
        { zero => 0, undefined => undef },
        "reject_each with value 'true'",
    );
    eq_or_diff(
        scalar $hash->reject_each(sub { $_[0] eq "one" }),
        { zero => 0, two => 2, undefined => undef },
        "reject_each with key eq",
    );
};

subtest reject_each_string => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->reject_each(0),
        { one => 1, two => 2 },
        "reject_each with string number 0",
    );
    eq_or_diff(
        { one => "one", zero => 0, two => 2 }->reject_each("one")->to_ref,
        { zero => 0, two => 2 },
        "reject_each with string",
    );
};

# TODO: undef when the old call style is gone

subtest reject_each_regex => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->reject_each(qr/2/),
        { one => 1, zero => 0 },
        "reject_each with regex",
    );
};

subtest reject_each_hashref_keys => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->reject_each({ 2 => 1 }),
        { one => 1, zero => 0 },
        "reject_each with regex",
    );
};

subtest reject_each_defined_basic => sub {
    my $hash = { one => 1, zero => 0, two => 2 };
    eq_or_diff(
        scalar $hash->reject_each_defined(),
        { },
        "reject_each_defined",
    );
};

done_testing();
