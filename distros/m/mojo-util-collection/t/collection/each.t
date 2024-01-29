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

use Data::Dumper;

$collection->each(sub {
    my $item = shift;

    $item->age($item->age + 1);
});

is_deeply($collection->only('id', 'age'), [
    {
        id  => 1,
        age => 20
    },
    {
        id  => 2,
        age => 22
    },
    {
        id  => 3,
        age => 23
    },
    {
        id  => 4,
        age => 24
    },
]);

done_testing();
