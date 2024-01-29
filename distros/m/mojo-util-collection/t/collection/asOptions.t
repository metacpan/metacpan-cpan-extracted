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

is_deeply($collection->asOptions('id', 'age'), [
    { value => 1, label => 19 },
    { value => 2, label => 21 },
    { value => 3, label => 22 },
    { value => 4, label => 23 },
]);

is_deeply($collection->asOptions('id', 'age', 'v', 'l'), [
    { v => 1, l => 19 },
    { v => 2, l => 21 },
    { v => 3, l => 22 },
    { v => 4, l => 23 },
]);

done_testing();
