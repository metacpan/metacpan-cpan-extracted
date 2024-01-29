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

is_deeply($collection->only('id', 'age'), [
    { id => 1, age => 19 },
    { id => 2, age => 21 },
    { id => 3, age => 22 },
    { id => 4, age => 23 },
]);

is_deeply($collection->only('id', 'full_name'), [
    { id => 1, full_name => 'Joe Doe' },
    { id => 2, full_name => 'Jane Doe' },
    { id => 3, full_name => 'John Doe' },
    { id => 4, full_name => 'Jill Doe' },
]);

done_testing();
