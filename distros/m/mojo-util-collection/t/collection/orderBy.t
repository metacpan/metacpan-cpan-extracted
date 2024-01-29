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
            age        => 18
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

is_deeply($collection->orderBy('age')->only('id', 'age'), [
    { id => 2, age => 18 },
    { id => 1, age => 19 },
    { id => 3, age => 22 },
    { id => 4, age => 23 }
]);


is_deeply($collection->orderBy('age', 'desc')->only('id', 'age'), [
    { id => 4, age => 23 },
    { id => 3, age => 22 },
    { id => 1, age => 19 },
    { id => 2, age => 18 }
]);

done_testing();
