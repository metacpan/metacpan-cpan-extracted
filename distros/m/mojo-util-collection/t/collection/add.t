#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Collection;
use Mojo::Util::Model::User;

my $collection = Mojo::Util::Collection->new(
    items => [
        {
            id         => 1,
            first_name => 'Joe',
            last_name  => 'Doe',
            age        => 19
        },
        {
            id         => 2,
            first_name => 'Jane',
            last_name  => 'Doe',
            age        => 21
        },
        {
            id         => 3,
            first_name => 'John',
            last_name  => 'Doe',
            age        => 22
        },
        {
            id         => 4,
            first_name => 'Jill',
            last_name  => 'Doe',
            age        => 23
        },
    ],
    model => Mojo::Util::Model::User->new
);

my $model = Mojo::Util::Model::User->new(
    id         => 5,
    first_name => 'Jack',
    last_name  => 'Doe',
    age        => 30
);

isa_ok($collection->add($model), 'Mojo::Util::Collection');
is($collection->count, 5);
is($collection->last, $model);

$collection->add({
    id         => 6,
    first_name => 'Jill',
    last_name  => 'Doe',
    age        => 23
});

is($collection->count, 6);
is($collection->last->id, 6);

$collection->add([
    {
        id         => 7,
        first_name => 'Jill',
        last_name  => 'Doe',
        age        => 23
    },
    {
        id         => 8,
        first_name => 'Jill',
        last_name  => 'Doe',
        age        => 23
    },
]);

is($collection->count, 8);
is($collection->get(6)->id, 7);
is($collection->last->id, 8);

my $other_collection = Mojo::Util::Collection->new(
    items => [
        {
            id         => 9,
            first_name => 'Jill',
            last_name  => 'Doe',
            age        => 23
        },
        {
            id         => 10,
            first_name => 'Jill',
            last_name  => 'Doe',
            age        => 23
        },
    ],
    model => Mojo::Util::Model::User->new
);

$collection->add($other_collection);

is($collection->count, 10);
is($collection->get(8)->id, 9);
is($collection->last->id, 10);

done_testing();
