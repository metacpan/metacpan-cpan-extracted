#!/usr/bin/perl

use strict;
use warnings;

{
    package ByTest;

    use WebService::Box::Types::Library qw(BoxPerson);
    use Moo;

    has person => (
        is     => 'ro',
        isa    => BoxPerson,
        coerce => BoxPerson()->coercion,
    );
}

use Test::More;
use Test::Exception;

use WebService::Box::Types::By;

my $by_test_1 = ByTest->new(
    person => WebService::Box::Types::By->new(
        type  => 'user',
        id    => 123,
        name  => 'renee b',
        login => 'reneeb',
    ),
);

isa_ok $by_test_1, 'ByTest';

is $by_test_1->person->type, 'user', 'user';
is $by_test_1->person->id, 123, 'id';
is $by_test_1->person->name, 'renee b', 'name';
is $by_test_1->person->login, 'reneeb', 'login';

my $by_test_2 = ByTest->new(
    person => {
        type  => 'user',
        id    => 123,
        name  => 'renee b',
        login => 'reneeb',
    },
);

is $by_test_2->person->type, 'user', 'user';
is $by_test_2->person->id, 123, 'id';
is $by_test_2->person->name, 'renee b', 'name';
is $by_test_2->person->login, 'reneeb', 'login';

done_testing();
