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
        {
            id         => 5,
            first_name => 'Jack',
            last_name  => 'Doe',
            age        => 24
        },
        {
            id         => 6,
            first_name => 'Jenny',
            last_name  => 'Doe',
            age        => 25
        },
        {
            id         => 7,
            first_name => 'Jesse',
            last_name  => 'Doe',
            age        => 26
        },
    ],
    model => Mojo::Util::Model::User->new
);

$collection->splice;

is_deeply($collection->lists('id'), [2, 3, 4, 5, 6, 7]);

$collection->splice(2);

is_deeply($collection->lists('id'), [4, 5, 6, 7]);

$collection->splice(1, 2);

is_deeply($collection->lists('id'), [4, 7]);

done_testing();
