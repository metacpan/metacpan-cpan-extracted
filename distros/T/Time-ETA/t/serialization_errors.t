use strict;
use warnings;

use Test::More;
use Time::ETA;

sub test_sub_can_spawn_return_false {
    my ($string) = @_;

    my $result = Time::ETA->can_spawn($string);

    ok(not($result), "can_spawn() return false");

    return '';
}

sub check_no_string {
    eval {
        my $eta = Time::ETA->spawn();
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. No serialized data specified\./,
        "spawn() does not work without serialized string",
    );

    test_sub_can_spawn_return_false();
}

sub check_not_yaml {

    my $string = "incorrect";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Got error from YAML parser:/,
        "spawn() does not work incorrect serialized string",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_data {

    my $string = "--- []
";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Got incorrect serialized data/,
        "spawn() does not work incorrect serialized string",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_no_version {
    my $string = "---
_milestones: 10
_passed_milestones: 4
";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data does not contain version/,
        "spawn() does not work without serialized api version",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_version {

    my $string = "---
_milestones: 10
_passed_milestones: 4
_version: 1044
";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    my $v = Time::ETA::_get_version();

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Version $v can work only with serialized data version/,
        "spawn() works only with some serialized api versions",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_milestones {

    my $string = "---
_milestones: -3
_passed_milestones: 4
_version: $Time::ETA::SERIALIZATION_API_VERSION
";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data contains incorrect number of milestones/,
        "spawn() works only with correct number of milestones",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_passed_milestones {
    my $string = "---
_milestones: 186
_passed_milestones: asdf
_version: $Time::ETA::SERIALIZATION_API_VERSION
";

    eval {
        my $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data contains incorrect number of passed milestones/,
        "spawn() works only with correct number of passed milestones",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_no_start_time_info {
    my $string = "---
_milestones: 186
_passed_milestones: 10
_version: $Time::ETA::SERIALIZATION_API_VERSION
";

    my $eta;
    eval {
        $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data contains incorrect data for start time/,
        "spawn() works only with correct start time info",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_seconds_in_start_time_info {
    my $string = "---
_milestones: 186
_passed_milestones: 10
_version: $Time::ETA::SERIALIZATION_API_VERSION
_start:
  - mememe
  - 631816
";

    my $eta;
    eval {
        $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data contains incorrect seconds in start time/,
        "spawn() works only with correct start time info",
    );

    test_sub_can_spawn_return_false($string);
}

sub check_incorrect_microseconds_in_start_time_info {
    my $string = "---
_milestones: 186
_passed_milestones: 10
_version: $Time::ETA::SERIALIZATION_API_VERSION
_start:
  - 1362672010
  - -934
";

    my $eta;
    eval {
        $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Serialized data contains incorrect microseconds in start time/,
        "spawn() works only with correct start time info",
    );

    test_sub_can_spawn_return_false($string);
}

sub main {
    check_no_string();
    check_not_yaml();
    check_incorrect_data();
    check_no_version();
    check_incorrect_version();
    check_incorrect_milestones();
    check_incorrect_passed_milestones();
    check_no_start_time_info();
    check_incorrect_seconds_in_start_time_info();
    check_incorrect_microseconds_in_start_time_info();

    done_testing();
}

main();
