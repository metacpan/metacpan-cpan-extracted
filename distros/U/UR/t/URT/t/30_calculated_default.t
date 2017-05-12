#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal qw(exception);

use UR qw();

subtest 'class initialization' => sub {
    plan tests => 4;

    subtest 'default_value and calculated_default are incompatible' => sub {
        plan tests => 2;
        my %thing = (
            class_name => 'URT::Thing',
            has => [
                name => {
                    is => 'String',
                    default_value => 'foo',
                    calculated_default => 1,
                },
            ],
        );
        local *URT::Thing::__default_name__ = sub { 'some name' };
        my $exception = exception { UR::Object::Type->define(%thing) };
        ok($exception, 'got an exception when trying to use `default_value` and `calculated_default`');

        delete $thing{has}->[1]->{default_value};
        $exception = exception { UR::Object::Type->define(%thing) };
        ok(!$exception, 'did not get an exception when trying to use just `calculated_default`')
            or diag $exception;
    };

    subtest 'calculated_default validates method name' => sub {
        plan tests => 2;
        my %thing = (
            class_name => 'URT::Thing',
            has => [
                name => {
                    is => 'String',
                    calculated_default => 'some_method',
                },
            ],
        );
        my $exception = exception { UR::Object::Type->define(%thing) };
        ok($exception, 'got an exception when trying to use `calculated_default` without method defined');

        local *URT::Thing::some_method = sub { 'some name' };
        $exception = exception { UR::Object::Type->define(%thing) };
        ok(!$exception, 'did not get an exception when trying to use `calculated_default` with method defined')
            or diag $exception;
    };

    subtest 'calculated_default => 1 defaults to __default_PROP__' => sub {
        plan tests => 2;
        my %thing = (
            class_name => 'URT::Thing',
            has => [
                name => {
                    is => 'String',
                    calculated_default => 1,
                },
            ],
        );
        my $exception = exception { UR::Object::Type->define(%thing) };
        ok($exception, 'got an exception when trying to use `calculated_default` without method defined');

        local *URT::Thing::__default_name__ = sub { 'some name' };
        $exception = exception { UR::Object::Type->define(%thing) };
        ok(!$exception, 'did not get an exception when trying to use `calculated_default` with method defined')
            or diag $exception;
    };

    subtest 'calculated_default supports coderef' => sub {
        plan tests => 2;
        my %thing = (
            class_name => 'URT::Thing',
            has => [
                name => {
                    is => 'String',
                    calculated_default => sub { 'some name' },
                },
            ],
        );
        my $exception = exception { UR::Object::Type->define(%thing) };
        ok(!$exception, 'did not get an exception when trying to use `calculated_default` with method defined')
            or diag $exception;

        my $thing = URT::Thing->create();
        is($thing->name, 'some name', 'got default name');
    };
};

subtest 'dynamic default values' => sub {
    plan tests => 4;

    my $orig_foo = 'A';
    my $foo = $orig_foo;
    local *URT::ThingWithDefaultSub::__default_name__ = sub { $foo };
    UR::Object::Type->define(
        class_name => 'URT::ThingWithDefaultSub',
        has => [
            name => { is => 'String', calculated_default => 1 },
        ],
    );

    my $thing1 = URT::ThingWithDefaultSub->create();
    is($thing1->name, $foo, 'thing1 default name was resolved');

    $foo++;
    isnt($foo, $orig_foo, 'foo was changed');

    my $thing2 = URT::ThingWithDefaultSub->create();
    is($thing2->name, $foo, 'thing2 default name was resolved');

    isnt($thing1->name, $thing2->name, 'things have different names');
};

subtest 'with classwide property' => sub {
        plan tests => 16;
        my($name_calc_called, $rank_calc_called, $address_calc_called) = (0, 0, 0);
        my %thing = (
            class_name => 'URT::ThingWithClasswide',
            has_classwide => [
                name => {
                    is => 'String',
                    is_constant => 1,
                    calculated_default => sub { $name_calc_called++; 'some name' },
                },
                rank => {
                    is => 'String',
                    calculated_default => sub { $rank_calc_called++; 'private' },
                },
                address => {
                    is => 'String',
                    calculated_default => sub { $address_calc_called++, 'main st' },
                },
            ],
        );
        my $exception = exception { UR::Object::Type->define(%thing) };
        ok(!$exception, 'did not get an exception when trying to use `calculated_default` with method defined')
            or diag $exception;

        is($name_calc_called, 0, 'name calculation not called yet');
        is($rank_calc_called, 0, 'rank calculation not called yet');
        is($address_calc_called, 0, 'address calculation not called yet');

        is(URT::ThingWithClasswide->name, 'some name', 'got default name');
        is($name_calc_called, 1, 'name calculation was called');
        is(URT::ThingWithClasswide->rank, 'private', 'got default rank');
        is($rank_calc_called, 1, 'rank calculation was called');

        ok(URT::ThingWithClasswide->address('foo ln'), 'Set address');
        is(URT::ThingWithClasswide->address, 'foo ln', 'Address property was changes');
        is($address_calc_called, 0, 'address calculation was not called');

        $exception = exception { URT::ThingWithClasswide->name('foo') };
        like($exception,
            qr/Cannot change read-only class-wide property/,
            'Got exception trying to change read-only classwide property');
        is($name_calc_called, 1, 'name calculation was not called again');

        ok(URT::ThingWithClasswide->rank('general'), 'Changed rank');
        is(URT::ThingWithClasswide->rank, 'general', 'rank property changed');
        is($rank_calc_called, 1, 'name calculation was not called again');
};
