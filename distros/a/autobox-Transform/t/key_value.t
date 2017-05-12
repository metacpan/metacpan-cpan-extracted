use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

subtest key_value => sub {
    eq_or_diff(
        [ { present => "value", other => "other value" }->key_value("present") ],
        [
            present => "value",
        ],
        "Present key gives only that key",
    );

    eq_or_diff(
        [ scalar { present => "value", other => "other value" }->key_value("present") ],
        [
            { present => "value" },
        ],
        "Scalar context returns hashref",
    );

    eq_or_diff(
        [ {}->key_value("missing") ],
        [
            missing => undef,
        ],
        "Missing key gives original key with undef",
    );

    eq_or_diff(
        [ {}->key_value("missing", "new_name") ],
        [
            new_name => undef,
        ],
        "Missing key with new_name gives new_name key with undef",
    );
};

subtest key_value_exists => sub {
    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_exists("missing" ) ],
        [
        ],
        "Doesn't exist, not returned",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_exists("other") ],
        [
            other => undef,
        ],
        "present and undefined value found",
    );
    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_exists("present") ],
        [
            present => "value",
        ],
        "present and defined value found",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_exists("present", "alias") ],
        [
            alias => "value",
        ],
        "returned with new_key",
    );
};

subtest key_value_defined => sub {
    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_defined("missing" ) ],
        [
        ],
        "Doesn't exist, not returned",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_defined("other") ],
        [
        ],
        "present and undefined value not returned",
    );
    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_defined("present") ],
        [
            present => "value",
        ],
        "present and defined value found",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_defined("present", "alias") ],
        [
            alias => "value",
        ],
        "returned with new_key",
    );
};

subtest key_value_true => sub {
    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_true("missing" ) ],
        [
        ],
        "Doesn't exist, not returned",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_true("other") ],
        [
        ],
        "present and undefined value not returned",
    );
    eq_or_diff(
        [ { present => "value", other => undef, is_false => 0 }->key_value_if_true("is_false") ],
        [
        ],
        "present and false value not returned",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_true("present") ],
        [
            present => "value",
        ],
        "present and defined value found",
    );

    eq_or_diff(
        [ { present => "value", other => undef }->key_value_if_true("present", "alias") ],
        [
            alias => "value",
        ],
        "returned with new_key",
    );
};


done_testing();
